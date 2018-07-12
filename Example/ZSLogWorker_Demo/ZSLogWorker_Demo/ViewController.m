//
//  ViewController.m
//  ZSLogWorker_Demo
//
//  Created by zhushuaishuai on 2018/7/6.
//  Copyright © 2018年 zhushuaishuai. All rights reserved.
//

#import "ViewController.h"
#import <ZSLogWorker/ZSLogger.h>
#import <ZSLogWorker/ZSLoggerZipUpload.h>

#import <SSZipArchive/ZipArchive.h>
#import <AFNetworking/AFNetworking.h>
#import "ZSFTPManager.h"

#define ZSkLibraryDirectory [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES) lastObject]

#define ZSkLogDirectory [ZSkLibraryDirectory stringByAppendingString:@"/ZSData"]

#define ZSkUnZipLogDirectory [ZSkLogDirectory stringByAppendingString:@"/ZSLog"]

#define ZSkZipLogDirectory [ZSkLogDirectory stringByAppendingString:@"/zipZSLog"]

@interface ViewController ()<ZSFTPManagerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Delete log 7 days ago
    ZSLoggerCleanLog([[NSDate date] dateByAddingTimeInterval:-60*60*24*7.0]);

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (NSString *)archiveZip
{
    NSLog(@"yasuo...");

    NSString *logFilePath = [[ZSLogger shareManger] logDirectoryFilePath];
    NSString *zipPath = [NSString stringWithFormat:@"%@/%@",NSHomeDirectory(),@"ZSUnZip"];
    NSString *zipPath1 = [NSString stringWithFormat:@"%@/%@.zip",[[self class] createZipDirectory],@"123"];
    BOOL isZip = [SSZipArchive createZipFileAtPath:zipPath1 withContentsOfDirectory:logFilePath];

    if (!isZip) {
        NSLog(@"压缩失败");
        return nil;
    }
    return zipPath;
}

- (void)startUploading
{
//    NSString *filePath = [NSString stringWithFormat:@"%@/%@.zip",[[self class] createZipDirectory],@"123"];
    NSString *logFilePath = [[ZSLogger shareManger] logDirectoryFilePath];

    NSString *ftpUrl = @"ftp://218.66.16.77:2121/HC_MobileLog/mobile_iOS";
    NSString *ftpUsr = @"admin";
    NSString *ftpPass = @"hik12345+";

    ZSLoggerZipUpload *zipUpload = [[ZSLoggerZipUpload alloc]init];
    BOOL isSuccess = [zipUpload uploadFtp:logFilePath ftpUrl:ftpUrl ftpUsr:ftpUsr ftpPass:ftpPass];

//    BOOL isSuccess = [self uploadFtp:filePath ftpUrl:ftpUrl ftpUsr:ftpUsr ftpPass:ftpPass];
    if (isSuccess) {
        NSLog(@"startUploading");
    }
}

- (BOOL)uploadFtp:(NSString*)file ftpUrl:(NSString*)url ftpUsr:(NSString*)user ftpPass:(NSString*)pass
{
    ZSFTPManager *ftpManger = [[ZSFTPManager alloc] init];
    ftpManger.delegate = self;
    ZSFMServer *server = [ZSFMServer serverWithDestination:url username:user password:pass];
    BOOL isUploadSuccess = [ftpManger uploadFile:[NSURL URLWithString:file] toServer:server];
    return isUploadSuccess;
}

- (void)ftpManagerUploadProgressDidChange:(NSDictionary *)processInfo
{
    NSLog(@"ftpManagerUploadProgressDidChange");
}



+ (NSString *)createZipDirectory
{
    NSString *zipDirectoryPath = ZSkZipLogDirectory;
    BOOL isDir = YES;

    if (![[NSFileManager defaultManager] fileExistsAtPath:zipDirectoryPath isDirectory:&isDir])
    {
        BOOL ret = [[NSFileManager defaultManager] createDirectoryAtPath:zipDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        if (!ret)
        {
            //                NSLog(@"ZSLogger logDirectory fail");
            return nil;
        }
    }
    return zipDirectoryPath;
}

/**
 *  把.zip文件上传到服务器
 *
 *  @param zipName log.zip的文件全名
 */
+ (void)uploadLogWithZipName:(NSString *)zipName
                       error:(void(^)(NSDictionary *errDict))errorblock
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@%@",ZSkZipLogDirectory,zipName]]) {
//        [TNLog errorBlockWithErrDict:@{@"error_code":@"101",
//                                       @"error_msg" :@"file is not exist!"} error:errorblock];
        return;
    }
    NSURL *filePath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",ZSkZipLogDirectory,zipName]];


    AFHTTPSessionManager *manger = [AFHTTPSessionManager manager];
    manger.responseSerializer = [AFHTTPResponseSerializer serializer];
    manger.requestSerializer = [AFHTTPRequestSerializer serializer];
    manger.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/x-www-form-urlencoded",@"text/plain",@"application/json",nil];
    [manger POST:@"" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileURL:filePath name:@"zip" error:nil];

    } progress:^(NSProgress * _Nonnull uploadProgress) {

    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *result = [[NSString alloc] initWithData:responseObject  encoding:NSUTF8StringEncoding];
        NSLog(@"result =%@",result);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

    }];



}


- (IBAction)createLogZip:(id)sender {
    [self archiveZip];

}



- (IBAction)uncaughtException:(id)sender
{
    NSMutableArray * a = [NSMutableArray array];
    [a objectAtIndex:2];
}

- (IBAction)loglog:(id)sender
{

    int i = 0;
    NSString* logStr = @"this is a str";

    NSMutableString * veryLenStr = [NSMutableString stringWithFormat:@""];
    for (int i; i< (1ul<<20); ++i) {
        [veryLenStr appendString:@"1"];
    }

    /* DLog is a macro .Print cpp fileName and */
//    DLog(@"Test DLog");
//    DLog(nil);
//    DLog(@"");
//    DLog(@"  ");
//    DLog(@"",i);
//    DLog(@"%@",@"this is a format string");
//    DLog(@"%@",logStr);
//    NSString* format = @"int %2d string :%@";
//    // DLog(format); wrong  NSLog(format);
//    // DLog(format,i); wrong NSLog(format,i);
//    DLog(format,i,logStr);
//
//    DLog(@"%@",[NSDate date]);
//    DLog(@"%@",self);
    //    DLog(veryLenStr);

//    ZSLoggerCleanLog([NSDate date]);
    ZSLoggerUserName(@"admin");
    ZSLog(@"Test SSLog");
    ZSLog(nil);
    ZSLog(@"");
    ZSLog(@"  ");
    ZSLog(@"",i);
    ZSLog(@"%@",@"this is a format string");
    ZSLog(@"%@",logStr);
    NSString* format1 = @"int %2d string :%@";
    // SSLog(format1); wrong  NSLog(format1);
    // SSLog(format1,i); wrong NSLog(format1,i);
    ZSLog(format1,i,logStr);
    ZSLog(@"%@",[NSDate date]);
    ZSLog(@"%@",self);

    //    SSLog(veryLenStr);

}

- (IBAction)threadLog:(id)sender
{
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        for (int i=0; i<1000; ++i) {
//            DLog(@"global_queue %d",i);
//        }
//    });
//
//    for (int i = 0; i<1000; ++i) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            DLog(@"global_queue %d",i);
//        });
//    }

//    ZSLoggerUserID(@"testWO");
//    ZSLoggerUserName(@"testWO");
//    int i = 0;
//    NSString* logStr = @"this is a str 2";
//
//    NSMutableString * veryLenStr = [NSMutableString stringWithFormat:@""];
//    for (int i; i< (1ul<<20); ++i) {
//        [veryLenStr appendString:@"1"];
//    }
//
//    ZSLog(@"23334567894565Test SSLog 2");
//    ZSLog(@"2 %@",@"this is a format string 2 " );
//    ZSLog(@"2 %@",logStr);
//    NSString* format1 = @"int %2d string2 :%@";
//    ZSLog(format1,i,logStr);
//    ZSLog(@"2 %@",[NSDate date]);
//    ZSLog(@"2 %@",self);
    [self startUploading];
}

- (IBAction)cleanLog:(id)sender
{
    // Delete all log file
    ZSLoggerCleanLog([NSDate distantFuture]);
}
@end
