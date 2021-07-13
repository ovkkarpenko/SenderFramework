//
// Created by Roman Serga on 9/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatPickerManager.h"

@protocol ChatPickerManagerOneCompanyDisplayController <ChatPickerManagerDisplayController>

- (void)showOneCompanyAllowedError;

@end

@interface ChatPickerManagerOneCompany : ChatPickerManager

@property (nonatomic, strong) id<ChatPickerManagerOneCompanyDisplayController> displayController;

@end