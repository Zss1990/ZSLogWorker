//
//  ZSLoggerZipUpload.m
//  ZSLogWorker
//
//  Created by zhushuaishuai on 2018/7/10.
//

#import "ZSLoggerZipUpload.h"
#import "ZSLogger.h"
@import SSZipArchive;
#import "ZSFTPManager.h"
//@import AFNetworking;
//#import <SSZipArchive/ZipArchive.h>
//#import <AFNetworking/AFNetworking.h>

#define kZipStrTimeFormat      @"yyyy-MM-dd_HH.mm.ss.SSS"

@interface ZSLoggerZipUpload ()<ZSFTPManagerDelegate>

@end
@implementation ZSLoggerZipUpload


- (BOOL)uploadFtp:(NSString *)unZipPath ftpUrl:(NSString*)url ftpUsr:(NSString*)user ftpPass:(NSString*)pass
{
    NSString *zipPath = [self archiveZip:unZipPath];
    if (!zipPath) {
        return NO;
    }
    BOOL isUpload = [self uploadZipToFtp:zipPath ftpUrl:url ftpUsr:user ftpPass:pass];

    return isUpload;
}



- (NSString *)archiveZip:(NSString *)unZipPath
{
    if (unZipPath == nil) {
        return nil;
    }
    NSString *unZipName = [unZipPath componentsSeparatedByString:@"/"].lastObject;
    NSString *zipName = [NSString stringWithFormat:@"%@_%@",unZipName,[[NSDate date] stringWithFormat:kZipStrTimeFormat]];
    NSString *zipPath = [NSString stringWithFormat:@"%@/%@.zip",[[self class] createZipDirectory],zipName];
    BOOL isZip = [SSZipArchive createZipFileAtPath:zipPath withContentsOfDirectory:unZipPath];
    if (!isZip) {
        NSLog(@"压缩失败");
        return nil;
    }
    return zipPath;
}

- (BOOL)uploadZipToFtp:(NSString*)file ftpUrl:(NSString*)url ftpUsr:(NSString*)user ftpPass:(NSString*)pass
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
    NSString *zipDirectoryPath = ZS_k_ZipLogDirectory;
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

@end
