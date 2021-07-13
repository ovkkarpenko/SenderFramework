//
//  FileOperator.m
//  SENDER
//
//  Created by Eugene on 4/5/15.
//  Copyright (c) 2015 MiddleWare. All rights reserved.
//

#import "FileOperator.h"
#import "File.h"
#import "FileDownloadInfo.h"
#import "NSDictionaryToURLString.h"
#import "SenderRequestBuilder.h"
#import "ParamsFacade.h"
#import "CometController.h"

static FileOperator * operator;

@interface FileOperator()
{
    NSURL * destinationURL;
    NSURLSession * backSession;
}

//@property (nonatomic, strong) NSURLSession * session;
@property (nonatomic, strong) NSURL * docDirectoryURL;
@property (nonatomic, strong) NSMutableArray * arrFileDownloadData;

@end

@implementation FileOperator

+ (FileOperator *)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        operator = [[FileOperator alloc] init];
    });
    
    return operator;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.arrFileDownloadData = [[NSMutableArray alloc] initWithCapacity:0];
        NSArray * URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        self.docDirectoryURL = [URLs objectAtIndex:0];
    }
    return self;
}

- (NSURLSession *)downLoadSession
{
    if (!backSession) {
        
        NSString * randomSessionIdentifier = @"com.FileOperator.sender";
        NSURLSessionConfiguration * sessionConfiguration;
        sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:randomSessionIdentifier];
//        sessionConfiguration.HTTPMaximumConnectionsPerHost = 3;
        [sessionConfiguration setAllowsCellularAccess:YES];
        
        backSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                             delegate:self
                                        delegateQueue:nil];
        
         return backSession;

    }
    return backSession;
}


- (void)downloadFileToMessage:(Message *)message
{
    
}

- (void)downloadFileWithCompletionHandler:(RequestHolder *)holder
{
    FileDownloadInfo * fdi = [[FileDownloadInfo alloc] initWithRequestHolder:holder];
    [self startDownloadWithInfo:fdi];
    [self.arrFileDownloadData addObject:fdi];
}

- (void)uploadFileWithRequest:(NSURLRequest *)theRequest andRequestHolder:(RequestHolder *)holder
{
    
}

- (void)downloadPreviewToMessage:(Message *)message
{
//    return;
//    FileDownloadInfo * fdi = [[FileDownloadInfo alloc] initWithFileDownloadURL:message.file.prev_url];
//    
//    [self.arrFileDownloadData addObject:fdi];
//    [self startDownload:0];
}

- (void)uploadFileFromMessage:(Message *)message
{
    
}

- (void)startDownload:(int)queueIndex
{
    [self startDownloadWithInfo:(FileDownloadInfo *)[self.arrFileDownloadData objectAtIndex:queueIndex]];
}

- (void)startDownloadWithInfo:(FileDownloadInfo *)fdi
{
    // The isDownloading property of the fdi object defines whether a downloading should be started
    // or be stopped.
    if (!fdi.isDownloading) {
        // This is the case where a download task should be started.
        
        // Create a new task, but check whether it should be created using a URL or resume data.
        if (fdi.taskIdentifier == -1) {
            // If the taskIdentifier property of the fdi object has value -1, then create a new task
            // providing the appropriate URL as the download source.
            NSString * url = [fdi.downloadURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            fdi.downloadTask = [[self downLoadSession] downloadTaskWithURL:[NSURL URLWithString:url]];
            
            // Keep the new task identifier.
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
            
            // Start the task.
            [fdi.downloadTask resume];
        }
        else{
            // Create a new download task, which will use the stored resume data.
            fdi.downloadTask = [[self downLoadSession] downloadTaskWithResumeData:fdi.taskResumeData];
            [fdi.downloadTask resume];
            
            // Keep the new download task identifier.
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
        }
    }
    else{
        // Pause the task by canceling it and storing the resume data.
        [fdi.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
            if (resumeData != nil) {
                fdi.taskResumeData = [[NSData alloc] initWithData:resumeData];
            }
        }];
    }
    
    // Change the isDownloading property value.
    fdi.isDownloading = !fdi.isDownloading;
}

#pragma mark - NSURLSession Delegate method implementation

- (int)getFileDownloadInfoIndexWithTaskIdentifier:(unsigned long)taskIdentifier
{
    int index = 0;
    for (int i=0; i<[self.arrFileDownloadData count]; i++) {
        FileDownloadInfo * fdi = [self.arrFileDownloadData objectAtIndex:i];
        if (fdi.taskIdentifier == taskIdentifier) {
            index = i;
            break;
        }
    }
    
    return index;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    NSError *error;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    if (![self.arrFileDownloadData count]) return;
    
    int index = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
    FileDownloadInfo * fdi = [self.arrFileDownloadData objectAtIndex:index];
    if (fdi) {
        [self.arrFileDownloadData removeObject:fdi];
    }
    
    NSString * destinationFilename = fdi.holder.url.lastPathComponent;
    destinationURL = [self.docDirectoryURL URLByAppendingPathComponent:destinationFilename];
    
    if ([fileManager fileExistsAtPath:[destinationURL path]]) {
        [fileManager removeItemAtURL:destinationURL error:nil];
    }
    
    BOOL success = [fileManager copyItemAtURL:location
                                        toURL:destinationURL
                                        error:&error];
    
    if (success) {

        fdi.isDownloading = YES;
        fdi.isFinished = YES;
        // Set the initial value to the taskIdentifier property of the fdi object,
        // so when the start button gets tapped again to start over the file download.
        fdi.taskIdentifier = -1;
        
        // In case there is any resume data stored in the fdi object, just make it nil.
        fdi.taskResumeData = nil;
        
        NSError * error = nil;
        NSData * data = [NSData dataWithContentsOfURL:destinationURL options:NSDataReadingUncached error:&error];
        if (!error) {
        
            if (fdi && fdi.holder.completionHandler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        fdi.holder.completionHandler(@{@"fileData":data}, error);
                }];
            }
            //        [[
        }
//       NSOperationQueue mainQueue] addOperationWithBlock:^{
//            // Reload the respective table view row using the main thread.
//            [self.tblFiles reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
//                                 withRowAnimation:UITableViewRowAnimationNone];
//            
//        }];
        [fileManager removeItemAtURL:location error:nil];
        
    }
    else{
        // NSLog(@"Unable to copy temp file. Error: %@", [error localizedDescription]);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error != nil) {
        // NSLog(@"Download completed with error: %@", [error localizedDescription]);
    }
    else{
        // NSLog(@"Download finished successfully.");
        NSHTTPURLResponse * response = (NSHTTPURLResponse *)task.response;
        if ([response statusCode] >= 300) {
            // NSLog(@"Background transfer is failed, status code: %ld", (long)[response statusCode]);
            return;
        }
        else {
            
        }
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
        // NSLog(@"Unknown transfer size");
    }
    else{

        if (![self.arrFileDownloadData count]) return;
        int index = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
        FileDownloadInfo * fdi = [self.arrFileDownloadData objectAtIndex:index];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{

            fdi.downloadProgress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
            // NSLog(@"Progress download : %f", fdi.downloadProgress);
        }];
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    // NSLog(@"CALLFINICHEVENTS");
    [[self downLoadSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        if ([downloadTasks count] == 0) {
            if ([CometController sharedInstance].backgroundTransferCompletionHandler != nil)
            {
                void(^completionHandler)() = [CometController sharedInstance].backgroundTransferCompletionHandler;
                [CometController sharedInstance].backgroundTransferCompletionHandler = nil;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{ completionHandler(); }];
            }
        }
    }];
}

- (void)uploadFileFromURL:(RequestHolder *)holder
{
    FileDownloadInfo * fdi = [[FileDownloadInfo alloc] initWithRequestHolder:holder];
    [self.arrFileDownloadData addObject:fdi];
    
    NSString * sourceFilePath = holder.url;
    NSArray * extComp = [sourceFilePath componentsSeparatedByString:@"."];
   
    NSString * extension = [extComp lastObject];
    
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    params[@"filetype"] = extension;
    
    NSArray * comp = [sourceFilePath componentsSeparatedByString:@"//"];
    NSURL * sourceFileURL = [NSURL URLWithString:[comp lastObject]];
    
    uint64_t bytesTotalForThisFile = [[[NSFileManager defaultManager] attributesOfItemAtPath:sourceFileURL.absoluteString error:NULL] fileSize];
    
    NSString * urlAsString  = [[[SenderRequestBuilder sharedInstance] senderServerURL] stringByAppendingString:@"/upload"];
    
    if (params) {
        urlAsString = [urlAsString stringByAppendingString:@"?"];
        urlAsString = [urlAsString stringByAppendingString:[NSDictionaryToURLString convertToULRString:params]];
    }
    
    NSURL * url = [NSURL URLWithString:urlAsString];
    
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%llu", bytesTotalForThisFile] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionTask * uploadTask = [[self downLoadSession] uploadTaskWithRequest:request fromFile:[NSURL URLWithString:sourceFilePath]];

    // NSLog(@"UPLOAD");
    [uploadTask resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    // Upload progress
    // NSLog(@"Progress : %f", (float) totalBytesSent / totalBytesExpectedToSend);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    // NSLog(@"Response:: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    // NSLog(@"sadface :( %@", error);
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}

@end
