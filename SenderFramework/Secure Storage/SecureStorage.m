//
// Created by Roman Serga on 3/11/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "SecureStorage.h"
#import <SAMKeychain/SAMKeychain.h>

@implementation SecureStorage {

}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [SAMKeychain setAccessibilityType:kSecAttrAccessibleAlways];
    }
    return self;
}

- (NSString *)passwordForService:(NSString *)serviceName
                         account:(NSString *)account
                           error:(NSError **)error
{
    return [SAMKeychain passwordForService:serviceName account:account error:error];
}

- (BOOL)deletePasswordForService:(NSString *)serviceName
                         account:(NSString *)account
                           error:(NSError **)error
{
    return [SAMKeychain deletePasswordForService:serviceName account:account error:error];
}

- (BOOL)setPassword:(NSString *)password
         forService:(NSString *)serviceName
            account:(NSString *)account
              error:(NSError **)error
{
    return [SAMKeychain setPassword:password forService:serviceName account:account error:error];
}

@end
