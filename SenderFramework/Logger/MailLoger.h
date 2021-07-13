//
//  MailLoger.h
//  SENDER
//
//  Created by Eugene on 12/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface MailLoger : NSObject <MFMailComposeViewControllerDelegate>

- (void)writeMail;
- (void)addNewLogToLoger:(NSString *)newLog;

@end
