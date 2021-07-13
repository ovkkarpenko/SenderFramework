//
// Created by Roman Serga on 5/10/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SenderFrameworkLocalizedStringFromTable(key, table, comment) \
NSLocalizedStringFromTableInBundle((key), (table), SENDER_FRAMEWORK_BUNDLE, (comment))
#define SenderFrameworkLocalizedString(key, comment) SenderFrameworkLocalizedStringFromTable((key), @"SenderFramework", (comment))
