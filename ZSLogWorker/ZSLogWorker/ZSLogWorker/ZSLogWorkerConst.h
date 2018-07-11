
//
//  ZSLogWorkerConst.h
//  Pods
//
//  Created by zhushuaishuai on 2018/7/10.
//

#ifndef ZSLogWorkerConst_h
#define ZSLogWorkerConst_h

#define ZS_k_fileMaxSize (1ul << 24) // log files max size

#define ZS_k_LibraryDirectory [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES) lastObject]
#define ZS_k_LogDirectory [ZS_k_LibraryDirectory stringByAppendingString:@"/ZSData"]
#define ZS_k_UnZipLogDirectory [ZS_k_LogDirectory stringByAppendingString:@"/ZSLog"]
#define ZS_k_ZipLogDirectory [ZS_k_LogDirectory stringByAppendingString:@"/zipZSLog"]

#endif /* ZSLogWorkerConst_h */
