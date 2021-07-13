//
// Created by Roman Serga on 9/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatPickerViewController.h"
#import "ChatPickerManagerOneCompany.h"

@protocol AddToChatViewProtocol;

@interface ChatPickerOneCompanyViewController : ChatPickerViewController <ChatPickerManagerOneCompanyDisplayController,
        AddToChatViewProtocol>
@end