//
// Created by Roman Serga on 3/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "CountryListManager.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "NSArray+EqualContents.h"

@implementation CountryListManager

+ (void)clearCache
{
    [self setLocalCountryModels:nil];
    [self setLocalDefaultCountryModel:nil];
}

+ (void)loadCountryListWithCompletion:(void(^_Nullable)(NSArray <EnterPhoneCountryModel *>* countryModels, NSError * error, BOOL isCachedModels))completion
{
    NSArray * localResult = [self getLocalCountryModels];
    if (completion)
        completion(localResult, nil, YES);

    [[ServerFacade sharedInstance] getCountryListWithCompletionHandler:^(NSDictionary *response, NSError *error) {
        NSArray * result;

        if (!error && response[@"list"]) {
            result = @[];
            for (NSDictionary * dictionary in response[@"list"])
                result = [result arrayByAddingObject:countryModelFromDictionary(dictionary)];
            [self setLocalCountryModels:result];
            if (completion)
                completion(result, nil, NO);
        }
    }];
}

+ (void)loadDefaultCountryWithCompletion:(void(^_Nullable)(EnterPhoneCountryModel* countryModel, NSError * error, BOOL isCachedModel))completion
{
    EnterPhoneCountryModel * localResult = [self getLocalDefaultCountryModel];
    if (completion)
        completion(localResult, nil, YES);

    [[ServerFacade sharedInstance] getCurrentPhonePrefixWithCompletionHandler:^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && response)
            {
                EnterPhoneCountryModel * countryModel = defaultCountryModelFromDictionary(response);
                [self setLocalDefaultCountryModel:countryModel];
                if (completion)
                    completion(countryModel, nil, NO);
            }
        });
    }];
}

+ (NSString *)countriesFilePath
{
    NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString * countriesFilePath = [documentsPath stringByAppendingPathComponent:@"CountryList"];
    return countriesFilePath;
}


+ (NSString *)defaultCountryModelFilePath
{
    NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString * countriesFilePath = [documentsPath stringByAppendingPathComponent:@"DefaultCountryModel"];
    return countriesFilePath;
}

+ (NSArray<EnterPhoneCountryModel *>*)getLocalCountryModels
{
    NSString * countriesFilePath = [self countriesFilePath];
    return [NSKeyedUnarchiver unarchiveObjectWithFile:countriesFilePath];
}

+ (BOOL)setLocalCountryModels:(NSArray<EnterPhoneCountryModel *>*)models
{
    NSString * countriesFilePath = [self countriesFilePath];
    return [NSKeyedArchiver archiveRootObject:models toFile:countriesFilePath];
}


+ (EnterPhoneCountryModel *)getLocalDefaultCountryModel
{
    NSString * defaultModelPath = [self defaultCountryModelFilePath];
    EnterPhoneCountryModel * defaultModel =  [NSKeyedUnarchiver unarchiveObjectWithFile:defaultModelPath];
    if (!defaultModel)
    {
        defaultModel = [[EnterPhoneCountryModel alloc]initWithName:SenderFrameworkLocalizedString(@"default_country_name", nil)
                                                       countryCode:@""
                                                           flagURL:nil];
    }
    return defaultModel;
}

+ (BOOL)setLocalDefaultCountryModel:(EnterPhoneCountryModel *)model
{
    NSString * defaultModelPath = [self defaultCountryModelFilePath];
    return [NSKeyedArchiver archiveRootObject:model toFile:defaultModelPath];
}

EnterPhoneCountryModel * countryModelFromDictionary(NSDictionary * dictionary) {
    EnterPhoneCountryModel * countryModel;

    NSString * countryName = dictionary[@"name"];
    NSString * countryCode = dictionary[@"prefix"];

    if (countryName && countryCode)
    {
        NSString * flagImageURL;
        if ([dictionary[@"country"] isKindOfClass:[NSString class]] && [dictionary[@"country"]length])
            flagImageURL = [NSString stringWithFormat:@"https://s.sender.mobi/flag/%@.png", [dictionary[@"country"] lowercaseString]];

        countryModel = [[EnterPhoneCountryModel alloc]initWithName:countryName
                                                       countryCode:countryCode
                                                           flagURL:flagImageURL];
    }

    return countryModel;
}

EnterPhoneCountryModel * defaultCountryModelFromDictionary(NSDictionary * dictionary) {
    EnterPhoneCountryModel * countryModel;

    if (dictionary[@"cName"] &&
            [dictionary[@"country"] isKindOfClass:[NSString class]] &&
            [dictionary[@"country"]length] && dictionary[@"prefix"]) {

        NSString * flagImageURL = [NSString stringWithFormat:@"https://s.sender.mobi/flag/%@.png", [dictionary[@"country"] lowercaseString]];

        countryModel = [[EnterPhoneCountryModel alloc]initWithName:dictionary[@"cName"]
                                                       countryCode:dictionary[@"prefix"]
                                                           flagURL:flagImageURL];
    }

    return countryModel;
}

@end
