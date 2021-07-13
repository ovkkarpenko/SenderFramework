//
//  SenderJsonConvertrer.h
//  Privat24
//
//  Created by Eugene Gilko on 12/12/13.
//  Copyright (c) 2013 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SenderJsonConvertrer : NSObject

+ (NSString *)makeJsonFromArray:(NSArray *)data;

@end
