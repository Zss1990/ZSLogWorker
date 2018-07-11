//
//  ZSLogger.m
//  ZSLog
//
//  Created by zhushuaishuai on 2018/7/6.
//  Copyright © 2018年 zhushuaishuai. All rights reserved.
//
/*
参考：[C语言中的volatile关键字](https://blog.csdn.net/hherima/article/details/8939564)
 */


#import "ZSLogger.h"
#import <execinfo.h>
#import <signal.h>
#import <pthread.h>
#import <libkern/OSAtomic.h>
#import <UIKit/UIKit.h>

#define ZSLOG_TO_FILE       1
#define ZSLOG_TO_CONSOLE    1

#if ZSLOG_TO_CONSOLE
#define __NSLog(s, ...)   NSLog((s),##__VA_ARGS__)
#else
#define __NSLog(s, ...)   do {} while (0)
#endif




#define kStrTimeFormat      @"yyyy-MM-dd HH:mm:ss.SSS"
#define kLogFileFormat      @"yyyy-MM-dd_HH.mm.ss.SSS"
#define kLogInfo_FileDateFormat      @"yyyy-MM-dd_HH.mm"


#define kLogInfo_LocalStorage_Key     @"logInfoLocalStorageKey"

#define kNewLogTimerInterval     30

#define kZSLoggerThreadName @"__$ZSLoggerThreadName$__"


#pragma mark - NSDate (timeString)


@implementation NSDate (timeString)
- (NSString *)stringWithFormat:(NSString *)format
{
    if ((format == nil) || (format.length == 0)) {
        return nil;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter  alloc]  init];
    dateFormatter.dateFormat = format;
    return [dateFormatter stringFromDate:self];
}
- (NSDate *)dateWithFormat:(NSString *)format
{
    if ((format == nil) || (format.length == 0)) {
        return nil;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter  alloc]  init];
    dateFormatter.dateFormat = format;
    return [dateFormatter dateFromString:self];
}
@end
@interface NSString (date)
//format必须和strin包含的一致
- (NSString *)dateWithFormat:(NSString *)format;
@end
@implementation NSString (date)
- (NSDate *)dateWithFormat:(NSString *)format
{
    if ((format == nil) || (format.length == 0)) {
        return nil;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter  alloc]  init];
    dateFormatter.dateFormat = format;
    return [dateFormatter dateFromString:self];
}
@end
#pragma mark - LogMessage

@interface LogMessage : NSObject
@property (nonatomic, assign) int32_t   seq;
@property (nonatomic, strong) NSDate    *time;
@property (nonatomic, copy) NSString  *threadName;
@property (nonatomic, copy) NSString  *message;
@property (nonatomic, copy) NSString  *userID;

- (instancetype)initWithMessage:(NSString *)msg seq:(int32_t)seq;
- (NSString *)stringForWrite;
- (NSData *)dataForWrite;
@end

@implementation LogMessage

- (instancetype)initWithMessage:(NSString *)msg seq:(int32_t)seq userID:(NSString *)userID
{
    self = [self init];

    if (self) {
        _seq = seq;
        _time = [NSDate date];
        _threadName = [LogMessage currentThreadName];
        _message = msg;
        _userID = userID;
    }

    return self;
}

- (NSString *)stringForWrite
{
    return [NSString stringWithFormat:@"[%@]:[%@]%@\n",_userID,[_time stringWithFormat:kStrTimeFormat], _message];
//    return [NSString stringWithFormat:@"[%@]:[%@][%@]%@\n",_userID,[_time stringWithFormat:kStrTimeFormat], _threadName, _message];
}

- (NSData *)dataForWrite
{
    return [[self stringForWrite] dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)currentThreadName
{
    if ([NSThread isMainThread]) {
        return @"Main";
    }

    NSString *name = nil;

    if ([NSThread isMultiThreaded]) {
        NSThread *thread = [NSThread currentThread];
        name = [thread name];

        if ([name length] == 0) {
            NSMutableDictionary *threadDict = [thread threadDictionary];
            name = [threadDict objectForKey:kZSLoggerThreadName];

            if (name == nil) {
                name = [thread description];
                NSArray *prefixes = @[@"num = ", @"number = "];
                NSRange range = NSMakeRange(NSNotFound, 0);

                for (NSString *prefix in prefixes) {
                    range = [name rangeOfString:prefix];

                    if (range.location != NSNotFound) {
                        break;
                    }
                }

                if (range.location != NSNotFound) {
                    name = [name substringWithRange:NSMakeRange(range.location + range.length, [name length] - range.location - range.length - 1)];
                    name = [NSString stringWithFormat:@"%4ld", (long)[name integerValue]];
                    [threadDict setObject:name forKey:kZSLoggerThreadName];
                } else {
                    name = nil;
                }
            }
        }
    }

    if (name.length == 0) {
#if __LP64__
        int64_t pid = (int64_t)pthread_self();
        name = [NSString stringWithFormat:@"%lld", pid];
#else
        int32_t pid = (int32_t)pthread_self();
        name = [NSString stringWithFormat:@"%d", pid];
#endif
    }

    return name;
}

@end

#pragma mark - ZSLogger

@interface ZSLogger () {
    NSThread            *_workerThread;
    volatile BOOL       _stopWorkerThread; //每次直接从内存单元中获取该值，不再寄存器中获取，多个线程应用同时被多个任务共享
    CFRunLoopSourceRef  _logMessageRunLoopSource;
    CFRunLoopRef        _workRunLoopRef;

    NSLock          *_lockLogQueue;
    NSMutableArray  *_messageArray;
    int32_t         _messageSeq;  // the seq for next message

    NSOutputStream  *_writeStream;
    int32_t         _writeBytes;  // bytes written

    NSUncaughtExceptionHandler *_uncaughtExceptionHandler;

    NSDate  *_lastLogFileTime;
}
@property (nonatomic, copy) NSString          *currentLogFileName;
@property (nonatomic, copy) NSString          *nextLogFileName;
@property (nonatomic, strong) NSOutputStream    *writeStream;
@property (nonatomic, copy) NSString          *logDirectory; // default  Library/Data/ZSLog/
@end
@implementation ZSLogger
@synthesize logDirectory = _logDirectory, nextLogFileName = _nextLogFileName, writeStream = _writeStream;
+ (ZSLogger *)shareManger
{
    __strong static ZSLogger    *_singleton = nil;
    static dispatch_once_t      pred;

    dispatch_once(&pred, ^{
        _singleton = [[self alloc] init];
    });
    return _singleton;
}

- (instancetype)init
{
    self = [super init];

    if (self) {
//        _logDirectory = [NSString stringWithFormat:@"%@/Library/%@", NSHomeDirectory(),ZS_k_logDirectoryFilePath];
        _logDirectory = [NSString stringWithFormat:@"%@", ZS_k_UnZipLogDirectory];

        _fileMaxSize = ZS_k_fileMaxSize;
        _userId = @"";
        _stopWorkerThread = NO;
        _lockLogQueue = [[NSLock alloc] init];
        _messageSeq = 0;
        _currentLogFileName = self.nextLogFileName;
        _writeStream = nil;
        _writeBytes = 0;
        _messageArray = [NSMutableArray array];
        _workerThread = nil;
        _uncaughtExceptionHandler = NULL;
        _lastLogFileTime = [NSDate date];

        if (_logDirectory == nil) {
            return nil;
        }
    }
    return self;
}

- (NSString *)logDirectoryFilePath
{
    return _logDirectory;
}
- (void)start
{
    _stopWorkerThread = NO;

    if (_workerThread == nil) {
        _workerThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain) object:nil];
        [_workerThread start];
        ZSLog(@"ZSLogger start");
    }

}

- (void)stop
{
    if (_workerThread) {
        ZSLog(@"ZSLogger stop");
        _stopWorkerThread = YES;
        _workerThread = nil;
    }
}

- (void)logMessage:(NSString *)str
{
    int32_t seq = OSAtomicIncrement32Barrier(&_messageSeq);
    LogMessage *msg = [[LogMessage alloc] initWithMessage:str seq:seq userID:self.userId];

    if (!_stopWorkerThread) {
        [self performSelectorInBackground:@selector(pushMessageToQueue:) withObject:msg];
    }
}

- (void)pushMessageToQueue:(LogMessage *)msg
{
    if (msg == nil) {
        return;
    }

    [_lockLogQueue lock];
    int32_t     seq = msg.seq;
    NSUInteger  index = [_messageArray count];

    if (index) {
        LogMessage *lastMsg = nil;
        do {
            lastMsg = [_messageArray objectAtIndex:index - 1];
        } while (lastMsg.seq > seq && --index > 0);
    }

    [_messageArray insertObject:msg atIndex:index];
    [_lockLogQueue unlock];

    // Send signal
    if (_logMessageRunLoopSource) {
        CFRunLoopSourceSignal(_logMessageRunLoopSource);
    }
}

- (void)logFlush
{
    [self writeMessage];
}

- (void)writeMessage
{
    [_lockLogQueue lock];

    //每次写之前监测是否需要重新创建新log
    [self autoRedirectZSlog];

    while (_messageArray.count) {
        NSData *data = [[_messageArray objectAtIndex:0] dataForWrite];

        if (data && (data.length > 0)) {
            NSUInteger  toWrite = data.length;
            uint8_t     *fp = (uint8_t *)data.bytes;
            NSUInteger  len = 0;

            while (_writeBytes + toWrite > _fileMaxSize) {
                len = [self.writeStream write:fp maxLength:_fileMaxSize - _writeBytes];
                fp += len;
                toWrite -= len;
                _writeBytes = 0;
                self.writeStream = nil;
            }

            len = [self.writeStream write:fp maxLength:toWrite];
            _writeBytes += len;
        }

        [_messageArray removeObjectAtIndex:0];
    }

    [_lockLogQueue unlock];
}

- (NSOutputStream *)writeStream
{
    if (_writeStream == nil) {
        self.currentLogFileName = self.nextLogFileName;
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", self.logDirectory, self.currentLogFileName];
        _writeStream = [[NSOutputStream alloc] initToFileAtPath:filePath append:YES];
        [_writeStream open];
        _writeBytes = 0;
    }

    return _writeStream;
}


- (void)setWriteStream:(NSOutputStream *)writeStream
{
    [_writeStream close];
    _writeStream = writeStream;
}

//每次调用都会获取一个新的
- (NSString *)nextLogFileName
{
    NSString *logInfo_lastLogName = [[NSUserDefaults standardUserDefaults] valueForKey:kLogInfo_LocalStorage_Key];
    if (logInfo_lastLogName) {

        return logInfo_lastLogName;
    }
    _lastLogFileTime = [NSDate date];
    NSString *time = [_lastLogFileTime stringWithFormat:kLogFileFormat];
    _nextLogFileName = [NSString stringWithFormat:@"%@.log", time];

    static int index = 0;
    if ([self.currentLogFileName isEqualToString:_nextLogFileName]) {
        _nextLogFileName = [NSString stringWithFormat:@"%@_%02d.log", time, ++index];
    } else {
        index = 0;
    }
    [[NSUserDefaults standardUserDefaults] setObject:_nextLogFileName forKey:kLogInfo_LocalStorage_Key];
    return _nextLogFileName;
}




- (NSString *)nextLogFilePath
{
    return [NSString stringWithFormat:@"%@/%@", self.logDirectory, self.nextLogFileName];
}

- (NSString *)logDirectory
{
    if (_logDirectory) {
        BOOL isDir = YES;

        if (![[NSFileManager defaultManager] fileExistsAtPath:_logDirectory isDirectory:&isDir]) {
            BOOL ret = [[NSFileManager defaultManager] createDirectoryAtPath:_logDirectory withIntermediateDirectories:YES attributes:nil error:nil];

            if (!ret) {
                //                NSLog(@"ZSLogger logDirectory fail");
            }
        }
    }

    return _logDirectory;
}

#pragma mark log file manager
- (void)cleanLogBefore:(NSDate *)time
{
    if ([time isEqualToDate:[NSDate distantPast]]) {
        return;
    }

    BOOL deleteAll = [time isEqualToDate:[NSDate distantFuture]];

    NSString        *str = [time stringWithFormat:kLogFileFormat];
    NSString        *currentLogFile = self.currentLogFileName;
    NSMutableArray  *fileList = [self getLogFileNameList];

    for (NSString *fileName in fileList) {
        if ((deleteAll || (NSOrderedAscending == [fileName compare:str])) &&
            (![fileName isEqualToString:currentLogFile])) {
            [self deleteLogFile:fileName];
        }
    }
}

- (NSMutableArray *)getLogFileNameList
{
    NSMutableArray  *ret = [NSMutableArray arrayWithCapacity:10];
    NSString        *dirPath = self.logDirectory;
    NSArray         *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];

    for (NSString *filename in tmplist) {
        NSString *fullpath = [dirPath stringByAppendingPathComponent:filename];

        if ([[filename pathExtension] isEqualToString:@"log"]) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:fullpath]) {
                [ret addObject:filename];
            }
        }
    }

    return [ret count] ? ret : nil;
}

- (void)deleteLogFile:(NSString *)filename
{
    if ((filename == nil) || (filename.length == 0)) {
        return;
    }

    NSString *fullPath = [self.logDirectory stringByAppendingPathComponent:filename];
    [[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
}

#pragma mark write thread
void RunLoopSourcePerformRoutine(void *info)
{
    if (info != NULL) {
        [(__bridge ZSLogger *)info writeMessage];
    }
}

- (void)threadMain
{
    // add RunloopSource
    _logMessageRunLoopSource = [self addRunloopSource:((__bridge void *)self) perform:RunLoopSourcePerformRoutine];

    if (_logMessageRunLoopSource == NULL) {
        _stopWorkerThread = YES;
        return;
    }

    NSTimeInterval timeout = 0.10;

    while (!_stopWorkerThread) {
        @autoreleasepool {
            int result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, timeout, true);

            if (result == kCFRunLoopRunHandledSource) {
                timeout = 0.0;
                continue;
            }

            if ((result == kCFRunLoopRunFinished) || (result == kCFRunLoopRunStopped)) {
                break;
            }

            timeout = fmax(1.0, fmin(0.10, timeout + 0.0005));
        }
    }

    // dispose RunloopSource
    [self disposeRunloopSource:&_logMessageRunLoopSource];

    [self logFlush]; // write log to file
}

- (CFRunLoopSourceRef)addRunloopSource:(void *)info perform:(void *)perform
{
    CFRunLoopSourceContext  context = {0, info, NULL, NULL, NULL, NULL, NULL, NULL, NULL, perform};
    CFRunLoopSourceRef      sourceRef = CFRunLoopSourceCreate(NULL, 0, &context);

    if (sourceRef != NULL) {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopDefaultMode);
    }

    return sourceRef;
}

- (void)disposeRunloopSource:(CFRunLoopSourceRef *)sourceRef
{
    if (*sourceRef != NULL) {
        CFRunLoopSourceInvalidate(*sourceRef);
        CFRelease(*sourceRef);
        *sourceRef = NULL;
    }
}

#pragma mark NSLog
- (void)redirectNSLog
{
    //如果已经连接Xcode调试 则不重新定向
//    if (isatty(STDOUT_FILENO)) {
//        return;
//    }
//
//    //在模拟器不保存到文件中
//    UIDevice *device = [UIDevice currentDevice];
//    if([[device model] hasSuffix:@"Simulator"]){
//        return ;
//    }

    NSString *logFilePath = self.nextLogFilePath;

    /*实现重定向，把预定义的标准流文件定向到由path指定的文件中。标准流文件具体是指stdin、stdout和stderr*/
    /*stdin是标准输入流，默认为键盘；stdout是标准输出流，默认为屏幕；stderr是标准错误流，一般把屏幕设为默认*/
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
}

#pragma mark 监测新建路径

//自动重定向
- (void)autoRedirectZSlog
{
    if ([self checkIsNeedRedirect]) {
         [self redirectZSlog];
    }
}
//监测是否需要重新新的log文件
- (BOOL)checkIsNeedRedirect
{
    //每次获取之前先检测间隔多久需要新建一个.log，如果需新建需要重定向一次
    //60秒？
    NSTimeInterval logTimeGap = kNewLogTimerInterval;
    NSDate *nowTime = [NSDate date];
    NSDate *expectTime = [_lastLogFileTime dateByAddingTimeInterval:logTimeGap];

    //需要 重新写新的.log
    if ([nowTime compare:expectTime] > NSOrderedAscending) {
        return YES;
    }
    return NO;
}

- (void)redirectZSlog
{
    //删除本地文件名缓存
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLogInfo_LocalStorage_Key];
    //重新创建写入流实例
    self.writeStream = nil;
    [self writeStream];
}



#pragma mark UserID

- (void)setUserId:(NSString *)userId
{
    if (userId == nil) {
        userId = @"";
    }
    _userId = userId;
}

#pragma mark CrashLog
- (void)catchCrashLog
{
    [[ZSLogger shareManger] catchExceptionCrashLog];
    [[ZSLogger shareManger] catchSignalCrash];
}

static void UncaughtExceptionHandler(NSException *exception);

- (void)catchExceptionCrashLog
{
    if (_uncaughtExceptionHandler == NULL) {
        _uncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cancelCatchExceptionCrashLog)
                                                 name    :UIApplicationWillTerminateNotification
                                                 object  :nil];
    }
}

- (void)cancelCatchExceptionCrashLog
{
    if (_uncaughtExceptionHandler != NULL) {
        NSSetUncaughtExceptionHandler(_uncaughtExceptionHandler);
        _uncaughtExceptionHandler = NULL;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

static void signalCrashHandler(int sig, siginfo_t *info, void *context);

- (void)catchSignalCrash
{
    struct sigaction mySigAction;

    mySigAction.sa_sigaction = signalCrashHandler;
    mySigAction.sa_flags = SA_SIGINFO;

    sigemptyset(&mySigAction.sa_mask);
    sigaction(SIGQUIT, &mySigAction, NULL);
    sigaction(SIGILL, &mySigAction, NULL);
    sigaction(SIGTRAP, &mySigAction, NULL);
    sigaction(SIGABRT, &mySigAction, NULL);
    sigaction(SIGEMT, &mySigAction, NULL);
    sigaction(SIGFPE, &mySigAction, NULL);
    sigaction(SIGBUS, &mySigAction, NULL);
    sigaction(SIGSEGV, &mySigAction, NULL);
    sigaction(SIGSYS, &mySigAction, NULL);
    sigaction(SIGPIPE, &mySigAction, NULL);
    sigaction(SIGALRM, &mySigAction, NULL);
    sigaction(SIGXCPU, &mySigAction, NULL);
    sigaction(SIGXFSZ, &mySigAction, NULL);
}

@end


#pragma mark - crashLog Handler
static bool __hasCaughtCrash = NO;
static void UncaughtExceptionHandler(NSException *exception)
{
    if (exception == nil) {
        return;
    }

    NSString        *name = [exception name];
    NSString        *reason = [exception reason];
    NSArray         *symbols = [exception callStackSymbols];
    NSMutableString *strSymbols = [[NSMutableString alloc] init];

    for (NSString *item in symbols) {
        [strSymbols appendString:@"\t"];
        [strSymbols appendString:item];
        [strSymbols appendString:@"\r\n"];
    }

    NSString    *logFilePath = [[ZSLogger shareManger].nextLogFilePath stringByAppendingString:@"_Crash.log"];
    NSString    *time = [[NSDate date] stringWithFormat:kStrTimeFormat];
    NSString    *crashLog = [NSString stringWithFormat:@"[%@]*** Terminating app due to uncaught exception '%@', reason: '%@'\n*** First throw call stack:\n(\n%@)", time, name, reason, strSymbols];

    __hasCaughtCrash = [crashLog writeToFile:logFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static void signalCrashHandler(int sig, siginfo_t *info, void *context)
{
    if (__hasCaughtCrash) {
        return;
    }

    NSMutableString *str = [NSMutableString string];

    [str appendString:@"Stack:\n"];
    void    *callstack[128];
    int     frames = backtrace(callstack, 128);
    char    **strs = backtrace_symbols(callstack, frames);

    for (int i = 0; i < frames; ++i) {
        [str appendFormat:@"%s\n", strs[i]];
    }

    NSString *logFilePath = [[ZSLogger shareManger].nextLogFilePath stringByAppendingString:@"_Crash.log"];
    __hasCaughtCrash = [str writeToFile:logFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - ZSLog API

void ZSLoggerUserName(NSString *userName)
{
    [[ZSLogger shareManger] setUserId:userName];
}


void ZSLog(NSString *format, ...)
{
#if ZSLOG_TO_FILE || ZSLOG_TO_CONSOLE
    va_list args;

    va_start(args, format);

    NSString *msgString = nil;

    if (format != nil) {
        msgString = [[NSString alloc] initWithFormat:format arguments:args];
    }

    va_end(args);
#if ZSLOG_TO_FILE
    [[ZSLogger shareManger] logMessage:msgString];
#endif

#if ZSLOG_TO_CONSOLE
    NSLog(@"%@", msgString);
#endif
#endif
}



void ZSLoggerStart(void)
{
    [[ZSLogger shareManger] start];
}

void ZSLoggerStop(void)
{
    [[ZSLogger shareManger] stop];
}

void ZSLoggerCleanLog(NSDate *time)
{
    [[ZSLogger shareManger] cleanLogBefore:time];
}

void ZSLoggerCatchCrash(void)
{
    [[ZSLogger shareManger] catchCrashLog];
}

void ZSLoggerRedirectNSLog(void)
{
    [[ZSLogger shareManger] redirectNSLog];
}

