//
//  FileDownloadInfo.h
//  SENDER
//
//  Created by Eugene on 4/5/15.
//  Copyright (c) 2015 MiddleWare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RequestHolder.h"

@interface FileDownloadInfo : NSObject

@property (nonatomic, strong) NSString * downloadURL;
@property (nonatomic, strong) NSURLSessionDownloadTask * downloadTask;
@property (nonatomic, strong) NSURLSessionDataTask * dataTask;
@property (nonatomic, strong) NSData * taskResumeData;
@property (nonatomic) double downloadProgress;
@property (nonatomic) BOOL isDownloading;
@property (nonatomic) BOOL isFinished;
@property (nonatomic) unsigned long taskIdentifier;
@property (nonatomic, strong) RequestHolder * holder;
@property (nonatomic, strong) NSMutableData * storedData;
@property (nonatomic, strong) NSString * cidID;

- (id)initWithFileDownloadURL:(NSString *)url;
- (id)initWithRequestHolder:(RequestHolder *)holder;

@end
