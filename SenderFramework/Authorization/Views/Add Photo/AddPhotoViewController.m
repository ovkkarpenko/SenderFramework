//
//  AddPhotoViewController.m
//  SENDER
//
//  Created by Roman Serga on 20/1/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "AddPhotoViewController.h"
#import "PBConsoleConstants.h"
#import "UIImage+Resize.h"
#import "WelcomeViewController.h"
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import "ParamsFacade.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface AddPhotoViewController ()

@property (weak, nonatomic) IBOutlet UILabel *addPhotoTitle;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *deletePhotoButton;
@property (weak, nonatomic) IBOutlet UIImageView *photoView;

@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@end

@implementation AddPhotoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.addPhotoTitle.textColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];

    [self clearScreen];

    self.photoView.layer.cornerRadius = self.photoView.frame.size.height / 2;
    self.photoView.clipsToBounds = YES;

    self.addPhotoButton.layer.cornerRadius = self.addPhotoButton.frame.size.height / 2;

    [self.deletePhotoButton setTitleColor:[[SenderCore sharedCore].stylePalette secondaryTextColor] forState:UIControlStateNormal];
    self.deletePhotoButton.tintColor = [[SenderCore sharedCore].stylePalette secondaryTextColor];
    
    [self localize];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isActive = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)localize
{
    self.addPhotoTitle.text = SenderFrameworkLocalizedString(@"add_photo_ios", nil);
    [self.deletePhotoButton setTitle:SenderFrameworkLocalizedString(@"delete_photo_ios", nil) forState:UIControlStateNormal];
}


- (IBAction)actAddPhoto:(id)sender
{
    NSString * alertTitle = SenderFrameworkLocalizedString(@"change_photo",nil);

    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction * libraryAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"select_from_gallery", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self selectPhoto];
                                                         }];

    UIAlertAction * cameraAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"take_photo", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               [self takePhoto];
                                                           }];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];



    [alertController addAction:libraryAction];
    [alertController addAction:cameraAction];
    [alertController addAction:cancelAction];
    [alertController mw_safePresentInViewController:self animated:YES completion:nil];
}

- (void)takePhoto
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"error_ios", nil)
                                                                        message:SenderFrameworkLocalizedString(@"device_without_camera_ios", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];
        [alert addAction:okAction];
        [alert mw_safePresentInViewController:self animated:YES completion:nil];
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)selectPhoto
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.allowsEditing = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    [self resizeAndSetImage:image];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)resizeAndSetImage:(UIImage *)image
{
    UIImageView * imgVtmp = [[UIImageView alloc] initWithImage:image];
    
    CGFloat props = imgVtmp.frame.size.width/imgVtmp.frame.size.height;
    
    CGSize gSize = CGSizeMake(250.0, 250.0*props);
    CGInterpolationQuality gQual = kCGInterpolationDefault;
    
    UIImage * fImage = [image resizedImage:gSize interpolationQuality:gQual];

    self.photoView.image = fImage;
    
    self.addPhotoTitle.hidden = YES;
    self.deletePhotoButton.hidden = NO;
    
    [PBConsoleConstants imageSetRounds:self.photoView];
}

- (IBAction)actRemovePhoto:(id)sender
{
    [self clearScreen];
}

- (void)registerButtonPressed:(id)sender
{
    BOOL shouldUploadPhoto = !self.deletePhotoButton.hidden;
    NSData * imageData = shouldUploadPhoto ? [[ParamsFacade sharedInstance] uiImageToNSData:self.photoView.image] : nil;
    self.isActive = NO;
    [self.presenter sendPhoto:imageData
                   completion:^(MWSenderAuthorizationStepModel * _Nullable stepModel, NSError * _Nullable error) {
                       if (error)
                           self.isActive = YES;
                   }];
}

- (void)clearScreen
{
    if (![self isViewLoaded])
        return;

    self.photoView.image = [UIImage imageFromSenderFrameworkNamed:@"_add_photo"];
    self.deletePhotoButton.hidden = YES;
    self.addPhotoTitle.hidden = NO;
}

@end
