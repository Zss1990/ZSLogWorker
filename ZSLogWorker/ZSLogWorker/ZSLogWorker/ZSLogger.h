//
//  ZSLogger.h
//  ZSLog
//
//  Created by zhushuaishuai on 2018/7/6.
//  Copyright © 2018年 zhushuaishuai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZSLogWorkerConst.h"


//#define ZS_k_logDirectoryFilePath @"ZSData/ZSLog/" //log file path in NSHomeDirectory/Library/

#define DLog(format, ...) do {ZSLog(@"[%@:%d]%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, (format) ? ([NSString stringWithFormat : (format), ##__VA_ARGS__]) : @"(null)"); } while (0)

#pragma mark - ZSLogger API

#ifdef __cplusplus
extern "C" {
#endif

    /**
     *  Start the log thread.
     */
    extern void ZSLoggerStart(void);

    /**
     *  Stop the log thread.
     */
    extern void ZSLoggerStop(void);

    /**
     *  Delete log file before the date
     */
    extern void ZSLoggerCleanLog(NSDate *time);

    /**
     *  Redirect NSLog to file. Do not need ZSLoggerStart()
     */
    extern void ZSLoggerRedirectNSLog(void);

    /**
     *  Catch crash info and write to file. Do not need ZSLoggerStart()
     */
    extern void ZSLoggerCatchCrash(void);

    /**
     *  Redirect NSLog to userID.   Do not need ZSLoggerStart()
     */
    extern void ZSLoggerUserName(NSString *userName);
    
    /**
     *  Log string to file.
     *  Notice:this function only work after ZSLoggerStart()
     *         and not work after ZSLoggerStop()
     */
    extern void ZSLog(NSString *format, ...)  NS_FORMAT_FUNCTION(1, 2);

#ifdef __cplusplus
}
#endif


@interface NSDate (timeString)
- (NSString *)stringWithFormat:(NSString *)format;
@end

#pragma mark - ZSLogger class

@interface ZSLogger : NSObject

+ (ZSLogger *)shareManger;

@property (nonatomic, assign) NSInteger fileMaxSize;    // default 1<<20
@property (nonatomic, copy) NSString * userId; // default @""

- (void)logMessage:(NSString *)str;

- (void)start;
- (void)stop;

- (void)catchCrashLog;
- (void)redirectNSLog;

- (NSString *)logDirectoryFilePath;

@end
