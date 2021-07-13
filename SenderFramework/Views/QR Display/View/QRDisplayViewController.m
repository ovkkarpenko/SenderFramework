//
//  QRDisplayViewController.m
//  SENDER
//
//  Created by Roman Serga on 21/12/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "QRDisplayViewController.h"
#import "SenderQRCodeGenerator.h"
#import "PBConsoleConstants.h"
#import "ServerFacade.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface QRDisplayViewController ()

@property (nonatomic, assign) CGFloat originalBrightness;

@end

@implementation QRDisplayViewController

@synthesize presenter = _presenter;

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    
    tipString = SenderFrameworkLocalizedString(@"qr_my_number_tip", nil);
    myPhoneTip.text = tipString;
    
    senderLogoImageView.image = [UIImage imageFromSenderFrameworkNamed:@"_QR_sender_logo"];
    
    qrImageView.backgroundColor = [UIColor whiteColor];

    self.title = SenderFrameworkLocalizedString(@"qr_title_show_code", nil);

    [self.presenter viewWasLoaded];

    self.originalBrightness = [[UIScreen mainScreen] brightness];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[SenderCore sharedCore].stylePalette customizeNavigationBar:self.navigationController.navigationBar];
    [[UIScreen mainScreen] setBrightness:1.0f];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIScreen mainScreen] setBrightness:self.originalBrightness];
}

-(void)setQrString:(NSString *)qrString
{
    _qrString = qrString;
    if ([self isViewLoaded])
        [self addQRImageForString:self.qrString];
}

-(void)addQRImageForString:(NSString *)string
{
    UIImage * qrImage = [SenderQRCodeGenerator qrImageForString:string
                                                imageSize:qrImageView.frame.size.width
                                                withColor:[UIColor blackColor]];
    if (qrImage)
        [qrImageView setImage:qrImage];
}

-(IBAction)goToSettings:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

-(void)dismissQR:(id)sender
{
    [self.presenter closeQRDisplay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)updateWithQrString:(NSString *)qrString
{
    phoneLabel.text = qrString;
    [self addQRImageForString:qrString];
}

- (void)prepareForPresentationWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{
    closeButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageFromSenderFrameworkNamed:@"close"]
                                                  style:UIBarButtonItemStylePlain
                                                 target:self
                                                 action:@selector(dismissQR:)];

    closeButton.tintColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    [[self navigationItem]setLeftBarButtonItem:closeButton];
}

- (void)prepareForDismissalWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{
}

@end
