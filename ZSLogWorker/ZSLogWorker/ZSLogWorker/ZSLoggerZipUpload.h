//
//  ZSLoggerZipUpload.h
//  ZSLogWorker
//
//  Created by zhushuaishuai on 2018/7/10.
//

#import <Foundation/Foundation.h>
#import "ZSLogWorkerConst.h"

@interface ZSLoggerZipUpload : NSObject

//- (NSString *)archiveZip:(NSString *)unZipPath comption:(void(^)(NSString *zipPath))comption;
- (BOOL)uploadFtp:(NSString *)unZipPath ftpUrl:(NSString*)url ftpUsr:(NSString*)user ftpPass:(NSString*)pass;
@end
