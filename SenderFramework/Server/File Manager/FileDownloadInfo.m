//
//  FileDownloadInfo.m
//  SENDER
//
//  Created by Eugene on 4/5/15.
//  Copyright (c) 2015 MiddleWare. All rights reserved.
//

#import "FileDownloadInfo.h"

@implementation FileDownloadInfo

- (id)initWithFileDownloadURL:(NSString *)url
{
    self = [super init];
    if (self)
    {
        self.downloadURL = url;
        self.downloadProgress = 0.0;
        self.isDownloading = NO;
        self.isFinished = NO;
        self.taskIdentifier = -1;
    }
    
    return self;
}

- (id)initWithRequestHolder:(RequestHolder *)holder
{
    self = [super init];
    if (self)
    {
        self.holder = holder;
        self.downloadURL = holder.url;
        self.downloadProgress = 0.0;
        self.isDownloading = NO;
        self.isFinished = NO;
        self.taskIdentifier = -1;
        self.storedData = [[NSMutableData alloc] initWithCapacity:0];
    }
    return self;
}

@end
