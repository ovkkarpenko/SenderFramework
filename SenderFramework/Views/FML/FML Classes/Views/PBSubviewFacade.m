//
//  PBSubViewFacade.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/22/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"
#import "ServerFacade.h"
#import "CoreDataFacade.h"
#import "PBConsoleConstants.h"
#import "ConsoleCaclulator.h"
#import "BitcoinUtils.h"
#import "BitcoinManager.h"
#import "SenderNotifications.h"
#import "PBImageView.h"
#import "ECCWorker.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "Owner.h"
#import "ChatPickerManager.h"
#import "ContactViewModel.h"
#import "ChatPickerViewController.h"
#import "TermsConditionsViewController.h"
#import "MWFMLStringParser.h"
#import "MainContainerModel.h"
#import "Contact.h"

@interface PBSubviewFacade ()

@end

@implementation PBSubviewFacade

- (id)initWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    if (self) {
        self.viewModel = submodel;
    }
    return self;
}

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    submodel.view = self;
}

- (Class)viewControllerClass:(NSString *)className
{
    return NSClassFromString(className);
}

- (void)updateView
{
    
}

- (NSDictionary *)robotInfoWithAction:(NSDictionary *)action
{
    NSMutableDictionary * robotInfo = [action mutableCopy];
    NSMutableDictionary * model = [[NSMutableDictionary alloc] initWithDictionary:[self.viewModel.topModel getDataFromModel]];
    [model setValuesForKeysWithDictionary:[self.viewModel getDataFromModel]];
    if (action[@"data"]) {
        for (id key in action[@"data"])
            model[key] = action[@"data"][key];
    }
    robotInfo[@"data"] = [model copy];
    return [robotInfo copy];
}

- (NSString *)bitcoinAddressWithAction:(NSDictionary *)action
{
    MainContainerModel * addressModel = [self.viewModel findModelWithName:action[@"addr"]];
    return addressModel.bitcoinAddress;
}

- (NSString *)bitcoinAmountWithAction:(NSDictionary *)action
{
    MainContainerModel * amountModel = [self.viewModel findModelWithName:action[@"summ"]];
    return amountModel.val;
}

- (void)doAction:(NSDictionary *)action
{
    if ([self.delegate respondsToSelector:@selector(handleAction:forActionView:)])
        [self.delegate handleAction:action forActionView:self];
}

-(void)setImage:(NSData *)imageData {}

- (void)submitOnChangeAction:(NSDictionary *)action
{
    if ([self.delegate respondsToSelector:@selector(submitOnChange:forActionView:)])
        [self.delegate submitOnChange:action forActionView:self];
}

- (void)setActive:(BOOL)active {}

- (void)setImageURL:(NSURL *)imageURL imageData:(NSData *)imageData forAction:(NSDictionary *)action
{
    MainContainerModel * model = [self.viewModel findModelWithName:action[@"to"]];
    if (model) model.val = imageURL.absoluteString;
    if ([self.viewModel.type isEqualToString:@"img"]) [self setImage:imageData];
}

- (void)setContact:(Contact *)contact forAction:(NSDictionary *)action
{
    NSString * actionField = action[@"to"];
    [self.viewModel addUser:contact forField:actionField];
    self.viewModel.bitcoinAddress = contact.bitcoinAddress;
}

- (void)setQRScanResult:(NSString *)qrScanResult forAction:(NSDictionary *)action
{
    NSDictionary * parsedString = parseBitcoinQRString(qrScanResult);
    NSString * actionField = action[@"to"];
    NSString * fieldToSetAmount = action[@"to_amt"];

    if (parsedString[kBitcoinQRPublicAddress])
    {
        MainContainerModel * modelBitcoinPay = [self.viewModel findModelWithName:actionField];
        if (modelBitcoinPay)
        {
            modelBitcoinPay.val = parsedString[kBitcoinQRPublicAddress];
            modelBitcoinPay.bitcoinAddress = modelBitcoinPay.val;
            [modelBitcoinPay updateView];
        }
        [self.viewModel setValue:parsedString[kBitcoinQRAmount] forField:fieldToSetAmount];
    }
    else
    {
        MainContainerModel * modelBitcoinPay = [self.viewModel findModelWithName:actionField];
        if (modelBitcoinPay)
        {
            modelBitcoinPay.val = qrScanResult;
            modelBitcoinPay.bitcoinAddress = qrScanResult;
            [modelBitcoinPay updateView];
        }
    }
}

- (void)setGoogleUser:(MWGoogleUser *)googleUser forAction:(NSDictionary *)action
{
    for (NSDictionary * viewModelAction in self.viewModel.actions) {
        if ([self.viewModel detectAction:viewModelAction] == SubmitOnChange) {
            if (self.viewModel.name && self.viewModel.val) {
                NSMutableDictionary * outData = [[NSMutableDictionary alloc] initWithDictionary:action[@"data"]];
                outData[self.viewModel.name] = self.viewModel.val;
                [self submitOnChangeAction:outData];
            }
        }
    }
}

- (void)setSignedKey:(NSString *)signedKey forAction:(NSDictionary *)action
{
    MainContainerModel * model = [self.viewModel findModelWithName:action[@"to"]];
    if (model) model.val = signedKey;
}

- (void)setLocation:(CLLocation *)location
locationDescription:(NSString *)locationDescription
          forAction:(NSDictionary *)action
{
    MainContainerModel * model = [self.viewModel findModelWithName:action[@"to"]];
    if (model)
    {
        CLLocationCoordinate2D coordinate2D = location.coordinate;
        NSString * coordinates = [NSString stringWithFormat: @"%f;%f", coordinate2D.latitude, coordinate2D.longitude];
        model.val = coordinates;
        model.title = locationDescription ?: @"";
    }
}

@end
