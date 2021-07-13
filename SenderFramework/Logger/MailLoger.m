//
//  MailLoger.m
//  SENDER
//
//  Created by Eugene on 12/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "MailLoger.h"
#import "CoreDataFacade.h"
#import "ParamsFacade.h"

@implementation MailLoger
{
    NSString * tempPathMain;
    NSString * tempPathBackUp;
    BOOL successPath;
    BOOL isSwapFiles;
    NSFileManager * fileManager;
}

- (id)init
{
    if (self) {
        [self initFilePath];
        [self startLogTimer];
    }
    return self;
}

- (void)initFilePath
{
    successPath = YES;
    
    fileManager = [NSFileManager defaultManager];
    NSData * empyData = [@"LogStarts" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    tempPathMain = [documentsDirectory stringByAppendingFormat:@"/logFileMain.txt"];
    tempPathBackUp = [documentsDirectory stringByAppendingFormat:@"/logFileBackUp.txt"];
    
    if ([fileManager fileExistsAtPath:tempPathMain] == NO) {
        successPath = [empyData writeToFile:tempPathMain atomically:YES];
    }
    if ([fileManager fileExistsAtPath:tempPathBackUp] == NO) {
         successPath = [empyData writeToFile:tempPathBackUp atomically:YES];
    }
}

- (void)startLogTimer
{
    isSwapFiles = NO;
    [NSTimer scheduledTimerWithTimeInterval:119 target:self
                                                selector:@selector(swapFiles)
                                                userInfo:nil
                                                repeats:YES];
}

- (void)swapFiles
{
    isSwapFiles = YES;
}

- (BOOL)appendToFile:(NSString *)path newData:(NSData *)data
{
    NSFileHandle * fh = [NSFileHandle fileHandleForWritingAtPath:tempPathMain];
    
    if(fh)
        @try
    {
        [fh seekToEndOfFile];
        [fh writeData:data];
        [fh closeFile];
        return YES;
    }
    @catch(id error) {
        // NSLog (@"WRITE ERROR");
    }
    
    return NO;
}

- (void)addNewLogToLoger:(NSString *)newLog
{
    if (!newLog || !newLog.length) {
        return;
    }
    
    if (isSwapFiles) {
//        NSData * empyData = [@"LogStarts" dataUsingEncoding:NSUTF8StringEncoding];
        
        if ([fileManager removeItemAtPath:tempPathBackUp error:NULL]) {
//            if ([empyData writeToFile:tempPathBackUp atomically:YES])
            
            if ([fileManager copyItemAtPath:tempPathMain
                                     toPath:tempPathBackUp  error:NULL]) {
                
                if ([fileManager removeItemAtPath:tempPathMain error:NULL]) {
                
                    
//                    if ([empyData writeToFile:tempPathMain atomically:YES])
                                    // NSLog(@"Copied successfully");
            }
        }
    
        }
        isSwapFiles = NO;
    }
    
    if (successPath) {
        
        NSString * logString = [NSString stringWithFormat:@"\n\n NEW LOG for %@ ==================================== \n %@",[NSDate date],newLog];
        
        BOOL succes = [self appendToFile:tempPathMain newData:[logString dataUsingEncoding:NSUTF8StringEncoding]];
        if (succes) {
//            // NSLog (@"Write successful");
        }
    }
}

- (void)writeMail
{
    NSData * mainData = [fileManager contentsAtPath:tempPathMain];
    NSData * backUpData = [fileManager contentsAtPath:tempPathBackUp];
    [self displayComposerSheet:mainData andBackLog:backUpData];
}

- (void)displayComposerSheet:(NSData *)mainLogFile andBackLog:(NSData *)backLogFile
{
    MFMailComposeViewController * picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setSubject:@"Check out this LOG!"];
    
    // Set up recipients
    NSArray * toRecipients = [NSArray arrayWithObject:@"efinalform@gmail.com"];
//    NSArray * ccRecipients = [NSArray arrayWithObjects:@"a.sysoff@gmail.com", nil];
    // NSArray *bccRecipients = [NSArray arrayWithObject:@"fourth@example.com"];
    
    [picker setToRecipients:toRecipients];
//    [picker setCcRecipients:ccRecipients];
    // [picker setBccRecipients:bccRecipients];
    
    [picker addAttachmentData:mainLogFile mimeType:@"text/txt" fileName:@"mainLog.txt"];
    [picker addAttachmentData:backLogFile mimeType:@"text/txt" fileName:@"backtLog.txt"];
    
    // Fill out the email body text
    NSString * emailBody = @"Logs file is attached";
    [picker setMessageBody:emailBody isHTML:NO];
    
//    [SENDER_SHARED_CORE.mainNavigationController presentViewController:picker animated:YES completion:NULL];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // Notifies users about errors associated with the interface
    switch (result)
    {
        case MFMailComposeResultCancelled:
            // NSLog(@"Result: canceled");
            break;
        case MFMailComposeResultSaved:
            // NSLog(@"Result: saved");
            [self addNewLogToLoger:@"Result: LOG saved"];
            break;
        case MFMailComposeResultSent:
            // NSLog(@"Result: sent");
            [self addNewLogToLoger:@"Result: LOG sent"];
            break;
        case MFMailComposeResultFailed:
            // NSLog(@"Result: failed");
            [self addNewLogToLoger:@"Result: LOG failed"];
            break;
        default:
            // NSLog(@"Result: not sent");
            [self addNewLogToLoger:@"Result: LOG not sent"];
            break;
    }
//    [SENDER_SHARED_CORE.mainNavigationController dismissViewControllerAnimated:YES completion:NULL];
}

@end
