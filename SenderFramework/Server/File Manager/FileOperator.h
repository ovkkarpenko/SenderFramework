//
//  FileOperator.h
//  SENDER
//
//  Created by Eugene on 4/5/15.
//  Copyright (c) 2015 MiddleWare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"
#import "RequestHolder.h"

@interface FileOperator : NSObject <NSURLSessionDelegate, NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

+ (FileOperator *)sharedInstance;

- (void)downloadFileToMessage:(Message *)message;
- (void)uploadFileFromMessage:(Message *)message;
- (void)downloadPreviewToMessage:(Message *)message;

- (void)downloadFileWithCompletionHandler:(RequestHolder *)holder;
- (void)uploadFileWithRequest:(NSURLRequest *)theRequest andRequestHolder:(RequestHolder *)holder;
- (void)uploadFileFromURL:(RequestHolder *)holder;

@end
