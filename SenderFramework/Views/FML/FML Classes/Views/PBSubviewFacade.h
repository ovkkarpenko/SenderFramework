//
//  PBSubViewFacade.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/22/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QRDisplayViewController.h"
#import "CameraManager.h"

@class MainContainerModel;
@class PBSubviewFacade;
@class MWGoogleUser;
@protocol QRScannerModuleDelegate;

@class Contact;
@class CLLocation;

@protocol PBSubviewDelegate <NSObject>

- (void)submitOnChange:(NSDictionary *)action forActionView:(PBSubviewFacade *)actionView;
- (UIViewController *)ownerViewController;
- (void)handleAction:(NSDictionary *)action forActionView:(PBSubviewFacade *)actionView;

@end

@interface PBSubviewFacade : UIView

@property (nonatomic, weak) MainContainerModel * viewModel;

@property (nonatomic, assign) id<PBSubviewDelegate> delegate;

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel;
- (id)initWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel;

- (void)updateView;

- (void)doAction:(NSDictionary *)action;
- (void)setImage:(NSData *)imageData;
//By default does nothing. Override in subclasses
- (void)setActive:(BOOL)active;

- (void)submitOnChangeAction:(NSDictionary *)action;

- (NSString *)bitcoinAddressWithAction:(NSDictionary *)action;
- (NSString *)bitcoinAmountWithAction:(NSDictionary *)action;

- (void)setContact:(Contact *)contact forAction:(NSDictionary *)action;
- (void)setQRScanResult:(NSString *)qrScanResult forAction:(NSDictionary *)action;
- (void)setImageURL:(NSURL *)imageURL imageData:(NSData *)imageData forAction:(NSDictionary *)action;
- (void)setGoogleUser:(MWGoogleUser *)googleUser forAction:(NSDictionary *)action;
- (void)setSignedKey:(NSString *)signedKey forAction:(NSDictionary *)action;
- (void)setLocation:(CLLocation *)location
locationDescription:(NSString *)locationDescription
          forAction:(NSDictionary *)action;

- (NSDictionary *)robotInfoWithAction:(NSDictionary *)action;

@end
