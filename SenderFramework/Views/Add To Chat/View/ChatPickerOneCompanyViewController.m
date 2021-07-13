//
// Created by Roman Serga on 9/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatPickerOneCompanyViewController.h"
#import <SenderFramework/SenderFramework-Swift.h>


@implementation ChatPickerOneCompanyViewController
{

}

- (NSString *)title
{
    return SenderFrameworkLocalizedString(@"add_participant_ios", nil);
}

- (void)showOnlyOneCompanyError
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"error_ios", nil)
                                                                    message:SenderFrameworkLocalizedString(@"error_public_chat_with_company_ios", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil];
    [alert addAction:okAction];
    [alert mw_safePresentInViewController:self animated:YES completion:nil];
}

- (void)showCannotAddToChatError
{
}


@end