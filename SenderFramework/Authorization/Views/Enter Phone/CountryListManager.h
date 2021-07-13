//
// Created by Roman Serga on 3/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EnterPhoneCountryModel;

@interface CountryListManager: NSObject

+ (void)loadCountryListWithCompletion:(void(^_Nullable)(NSArray <EnterPhoneCountryModel *>* countryModels, NSError * error, BOOL isCachedModels))completion;
+ (void)loadDefaultCountryWithCompletion:(void(^_Nullable)(EnterPhoneCountryModel* countryModel, NSError * error, BOOL isCachedModel))completion;
+ (void)clearCache;

EnterPhoneCountryModel * countryModelFromDictionary(NSDictionary * dictionary);
EnterPhoneCountryModel * defaultCountryModelFromDictionary(NSDictionary * dictionary);

@end