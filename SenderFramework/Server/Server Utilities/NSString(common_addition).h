//
//  NSString(common_addition).h
//  Privat24
//
//  Created by Leonid Lo on 2/27/12.
//  Copyright (c) 2012 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (common_addition)

- (NSString *)MD5String;

- (NSString*)SHA1_;

- (BOOL)isEmailValid;
//	checks if the inn valid
- (BOOL)isInnValid;
//  trims whitespaces and new line symbols from the beginning an the end
- (NSString *)trim;

//	returns a phone number (if the string can be treated as one, or nil)
- (NSString *)stringAsPhone;
//	returns a login text string (if the string can be treated as one, or nil)
- (NSString *)stringAsLogin;

- (BOOL)isPasswordValid;

- (NSString *)stringAsCurrency;

@end
