//
//  QRDisplayViewController.h
//  SENDER
//
//  Created by Roman Serga on 21/12/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QRScanView.h"

@protocol QRDisplayViewProtocol;
@protocol QRDisplayPresenterProtocol;
@protocol ModalInNavigationWireframeEventsHandler;

@interface QRDisplayViewController : UIViewController <QRDisplayViewProtocol,
        ModalInNavigationWireframeEventsHandler>
{

    @protected

    __weak IBOutlet UIView * qrImageBackground;

    __weak IBOutlet UIImageView * qrImageView;
    __weak IBOutlet UIImageView * senderLogoImageView;
    __weak IBOutlet UILabel * myPhoneTip;
    __weak IBOutlet UILabel * phoneLabel;

    UIBarButtonItem * closeButton;
    NSString * tipString;
    UILabel * titleLabel;
}

@property (nonatomic, strong, nullable) id<QRDisplayPresenterProtocol> presenter;
@property (nonatomic, strong) NSString * qrString;

- (IBAction)dismissQR:(id)sender;

@end
