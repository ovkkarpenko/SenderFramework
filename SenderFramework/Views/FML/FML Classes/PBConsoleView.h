//
//  PBConsoleView.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainContainerModel.h"
#import "PBButtonInFormView.h"
#import "PBSubviewFacade.h"
#import "PBLoadFileView.h"
#import "PBMapView.h"
#import "PBSelectedView.h"
#import "MWMessageView.h"

@class PBConsoleView;
@class MWGoogleUser;
@class CLLocation;

@protocol PBConsoleViewDelegate <NSObject>

- (void)handleAction:(NSDictionary *)action
      forConsoleView:(PBConsoleView *)consoleView
          actionView:(PBSubviewFacade *)actionView;

- (void)sendConsoleView:(PBConsoleView *)consoleView
             withAction:(NSDictionary *)action
             actionView:(PBSubviewFacade *)actionView;

- (UIViewController *)ownerViewController;

- (void)loadFileForFileView:(PBLoadFileView *)fileView inConsoleView:(PBConsoleView *)consoleView;
- (void)getLocationForMapView:(PBMapView *)mapView inConsoleView:(PBConsoleView *)consoleView;
- (void)selectFromValues:(NSArray *)values
           forSelectView:(PBSelectedView *)selectView
           inConsoleView:(PBConsoleView *)consoleView;

@end

@interface PBConsoleView : MWMessageView <PBButtonInFormViewDelegate,
                                          PBSubviewDelegate,
                                          PBLoadFileViewDelegate,
                                          PBMapViewDelegate,
                                          PBSelectedViewDelegate>

- (PBConsoleView *)initWithCellModel:(MainContainerModel *)cellModel
                             message:(Message *)message
                             forRect:(CGRect)rect
                  rootViewController:(UIViewController *)rootViewController;

- (PBConsoleView *)initWithCellModel:(MainContainerModel *)cellModel
                             message:(Message *)message
                             forRect:(CGRect)rect
                            delegate:(id<PBConsoleViewDelegate>)delegate;

@property (nonatomic, weak) UIViewController * rootViewController;
@property (nonatomic, strong) MainContainerModel * cellModel;
@property (nonatomic, weak) Message * message;
@property (nonatomic, weak) id<PBConsoleViewDelegate> delegate;

- (NSDictionary *)submitInfoWithAction:(NSDictionary *)action;

- (void)setContact:(Contact *)contact forActionView:(PBSubviewFacade*)actionView action:(NSDictionary *)action;

- (void)setQRScanResult:(NSString *)qrScanResult
          forActionView:(PBSubviewFacade*)actionView
                 action:(NSDictionary *)action;

- (void)setImageURL:(NSURL *)imageURL
          imageData:(NSData *)imageData
      forActionView:(PBSubviewFacade*)actionView
             action:(NSDictionary *)action;

- (void)setGoogleUser:(MWGoogleUser *)googleUser
        forActionView:(PBSubviewFacade*)actionView
            forAction:(NSDictionary *)action;

- (void)setSignedKey:(NSString *)signedKey forActionView:(PBSubviewFacade*)actionView forAction:(NSDictionary *)action;

- (void)setLocation:(CLLocation *)location
locationDescription:(NSString *)locationDescription
      forActionView:(PBSubviewFacade*)actionView
             action:(NSDictionary *)action;

- (NSDictionary * _Nullable)bitcoinTransactionResultWithAddress:(NSString *)address
                                                         amount:(NSString *)amount
                                              transactionResult:(NSString *)transactionResult
                                                     actionView:(PBSubviewFacade*)actionView
                                                         action:(NSDictionary *)action;

- (NSDictionary *)robotInfoWithActionView:(PBSubviewFacade*)actionView action:(NSDictionary *)action;

- (NSString *)bitcoinAddressForActionView:(PBSubviewFacade*)actionView action:(NSDictionary *)action;
- (NSString *)bitcoinAmountForActionView:(PBSubviewFacade*)actionView action:(NSDictionary *)action;


@end
