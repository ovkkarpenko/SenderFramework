//
//  NSDictionaryToURLString.h
//  MoneySend
//
//  Created by Eugene Gilko on 3/31/14.
//  Copyright (c) 2014 Eugene Gilko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionaryToURLString : NSObject
+ (NSString *)convertToULRString:(NSDictionary *)source;

NSString * convertToStringURL (NSDictionary * source);

@end
