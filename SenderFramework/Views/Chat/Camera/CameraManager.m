//
//  CameraManager.m
//  SENDER
//
//  Created by Nick Gromov on 11/14/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "CameraManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import "CometController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@class UsePhotoViewController;

@protocol UsePhotoViewControllerDelegate <NSObject>

- (void)usePhotoViewControllerDidCancel:(UsePhotoViewController *)controller;
- (void)usePhotoViewControllerDidDismiss:(UsePhotoViewController *)controller;
- (void)usePhotoViewControllerDidAccept:(UsePhotoViewController *)controller;

@end

@interface UsePhotoViewController: UIViewController

@property (nonatomic, weak) id<UsePhotoViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIImageView * imageView;

@end

@implementation UsePhotoViewController

+ (instancetype)controller
{
    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
    return [[self alloc] initWithNibName:@"UsePhotoViewController" bundle:NSBundle.senderFrameworkResourcesBundle];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)cancelButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(usePhotoViewControllerDidCancel:)])
        [self.delegate usePhotoViewControllerDidCancel:self];
}

- (IBAction)acceptButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(usePhotoViewControllerDidAccept:)])
        [self.delegate usePhotoViewControllerDidAccept:self];
}

- (IBAction)dismissButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(usePhotoViewControllerDidDismiss:)])
        [self.delegate usePhotoViewControllerDidDismiss:self];
}

@end

@interface CameraManager () {
    __weak UIViewController * parentController;
    __weak UIImagePickerController * imagePickerController;
    CameraType cameraType;
    BOOL isRecording;
    NSString * assetID;
    UIImage * image;
    Dialog * currentChat;

    IBOutlet UIImageView * photoImageView;
    __strong IBOutlet UIView * overlayCameraView;
    IBOutlet UIView * bottomBar;
    __strong IBOutlet UIView * usePhotoCameraView;
    __strong IBOutlet UIButton * backButton;
    IBOutlet UIButton * cancelButton;
    IBOutlet UIButton * changeCameraButton;
    IBOutlet UIButton * changeTypeButton;
    IBOutlet UIButton * startButton;
    IBOutlet UIButton * libraryButton;
    IBOutlet UIButton * flashModeButton;
}
//// overlayCameraView buttons
- (IBAction)cancelButtonClick:(id)sender;
- (IBAction)changeCameraButtonClick:(id)sender;
- (IBAction)changeTypeButtonClick:(id)sender;
- (IBAction)startButtonClick:(id)sender;
- (IBAction)libraryButtonClick:(id)sender;
- (IBAction)changeFlashModeButtonClick:(id)sender;
- (IBAction)usePhotoButtonClick:(id)sender;
- (IBAction)backButtonClick:(id)sender;

@end

@implementation CameraManager

- (id)initWithParentController:(UIViewController *)controller chat:(Dialog *)chat
{
    if (self = [super init]) {
        parentController = controller;
        cameraType = CameraTypeImage;
        isRecording = NO;
        currentChat = chat;
    }
    return self;
}

- (void)dealloc
{
    imagePickerController = nil;
    parentController = nil;
}

- (void)showCamera
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus != AVAuthorizationStatusAuthorized)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(granted)
                    [self popCamera];
                else
                    [self showCameraPermissionAlert];
            });
         }];
    }
    else {
        [self popCamera];
    }
}

- (void)popCamera
{
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.allowsEditing = NO;
    picker.delegate = self;
    picker.showsCameraControls = NO;
    picker.mediaTypes = @[(NSString *) kUTTypeImage,(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];

    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
    [NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"OverlayCameraView" owner:self options:nil];
    overlayCameraView.frame =  CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    picker.cameraOverlayView = overlayCameraView;
    
    float yOffset = 44.0;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, yOffset);
    CGFloat widthScale = SCREEN_WIDTH / 320.0f;
    CGFloat heightScale = SCREEN_HEIGHT / 568.0f + 0.1f;
    
    picker.cameraViewTransform = CGAffineTransformScale(translate, widthScale, heightScale);
    overlayCameraView = nil;
    [parentController presentViewController:picker animated:YES completion:NULL];
    imagePickerController = picker;
}

- (IBAction)cancelButtonClick:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cameraManagerDidFinishWithError:)])
        [self.delegate cameraManagerDidFinishWithError:nil];
}

- (IBAction)changeCameraButtonClick:(id)sender
{
    if (imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    else {
        imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
    flashModeButton.hidden = ![UIImagePickerController isFlashAvailableForCameraDevice:imagePickerController.cameraDevice];
}

- (IBAction)changeTypeButtonClick:(id)sender
{
    if (cameraType == CameraTypeImage) {
        cameraType = CameraTypeVideo;
        imagePickerController.mediaTypes = @[(NSString *) kUTTypeMovie];
        
        [startButton setBackgroundImage:[UIImage imageFromSenderFrameworkNamed:@"start_recording"] forState:UIControlStateNormal];
        [changeTypeButton setBackgroundImage:[UIImage imageFromSenderFrameworkNamed:@"media_photo"] forState:UIControlStateNormal];
    }
    else {
        cameraType = CameraTypeImage;
        imagePickerController.mediaTypes = @[(NSString *) kUTTypeImage];
        
        [startButton setBackgroundImage:[UIImage imageFromSenderFrameworkNamed:@"button_take_photo"] forState:UIControlStateNormal];
        [changeTypeButton setBackgroundImage:[UIImage imageFromSenderFrameworkNamed:@"media_camera"] forState:UIControlStateNormal];
        [flashModeButton setHidden:[UIImagePickerController isFlashAvailableForCameraDevice:imagePickerController.cameraDevice]];
    }
}

- (IBAction)startButtonClick:(id)sender
{
    if (cameraType == CameraTypeImage) {
        [imagePickerController takePicture];
    }
    else {
        if (!isRecording) {
            isRecording = [imagePickerController startVideoCapture];
        }
        else {
            [imagePickerController stopVideoCapture];
        }
    }
}

- (IBAction)libraryButtonClick:(id)sender
{
    if (imagePickerController.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    else
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
}

- (IBAction)changeFlashModeButtonClick:(id)sender
{
    UIButton * button = (UIButton *)sender;
    if ([UIImagePickerController isFlashAvailableForCameraDevice:imagePickerController.cameraDevice]) {
        if (imagePickerController.cameraFlashMode == UIImagePickerControllerCameraFlashModeAuto) {
            imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
            [button setImage:[UIImage imageFromSenderFrameworkNamed:@"flash_disabled"] forState:UIControlStateNormal];
        }
        else {
            imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
            [button setImage:[UIImage imageFromSenderFrameworkNamed:@"flash_auto"] forState:UIControlStateNormal];
        }
        [button setHidden:NO];
    }
    else {
        [button setHidden:YES];
    }
}

- (IBAction)usePhotoButtonClick:(id)sender
{
    UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:SenderFrameworkLocalizedString(@"send_photo", nil)
                                                          message:SenderFrameworkLocalizedString(@"send_photo_question_ios", nil)
                                                         delegate:self
                                                cancelButtonTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                otherButtonTitles: SenderFrameworkLocalizedString(@"ok_ios", nil),nil];

    [myAlertView show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:SenderFrameworkLocalizedString(@"error_camera_not_available", nil)])
    {
        if (buttonIndex != [alertView cancelButtonIndex])
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    else
    {
        if (buttonIndex == 1)
        {
            [self finishPickingImage:image withAssetID:assetID];
            image = nil;
        }
        else
        {
          image = nil;
          [self backButtonClick:self];
        }
    }
}

- (IBAction)backButtonClick:(id)sender
{
    if (imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        [imagePickerController dismissViewControllerAnimated:NO completion:nil];
    }
    else
    {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        [NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"OverlayCameraView" owner:self options:nil];
        overlayCameraView.frame = imagePickerController.cameraOverlayView.frame;
        imagePickerController.cameraOverlayView = overlayCameraView;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString * type = info[UIImagePickerControllerMediaType];
    
    if ([type isEqualToString:(NSString *)kUTTypeVideo] || [type isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL * assetURL = (NSURL *)info[UIImagePickerControllerReferenceURL];
        if (assetURL != nil)
        {
            PHAsset * asset = [[PHAsset fetchAssetsWithALAssetURLs:@[assetURL] options:nil] lastObject];
            if (asset)
            {
                NSTimeInterval durationOfFile = asset.duration;
                if ([self.delegate respondsToSelector:@selector(cameraManager:didFinishPickingVideoWithAssetID:duration:)])
                {
                    [self.delegate cameraManager:self
                didFinishPickingVideoWithAssetID:asset.localIdentifier
                                        duration:durationOfFile];
                }
            }
        }
    }
    else
    {
        image = (UIImage*)info[UIImagePickerControllerOriginalImage];
        NSURL * assetURL = (NSURL *)info[UIImagePickerControllerReferenceURL];
        if (assetURL)
        {
            PHAsset * asset = [[PHAsset fetchAssetsWithALAssetURLs:@[assetURL] options:nil] lastObject];
            assetID = asset.localIdentifier;
        }
        else
        {
            assetID = nil;
        }

        UsePhotoViewController * usePhotoViewController = [UsePhotoViewController controller];
        usePhotoViewController.delegate = self;
        usePhotoViewController.view;
        usePhotoViewController.imageView.image = image;

        [imagePickerController presentViewController:usePhotoViewController animated:NO completion:nil];
    }
}

- (void)finishPickingImage:(UIImage *)pickedImage withAssetID:(NSString *)assetID
{
    if ([self.delegate respondsToSelector:@selector(cameraManager:didFinishPickingImage:withAssetID:)])
        [self.delegate cameraManager:self didFinishPickingImage:pickedImage withAssetID:assetID];
}

- (void)showCameraPermissionAlert
{
    UIAlertView * cameraNotAvailiableAlert = [[UIAlertView alloc] initWithTitle:SenderFrameworkLocalizedString(@"error_camera_not_available", nil)
                                                                        message:nil
                                                                       delegate:self
                                                              cancelButtonTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                              otherButtonTitles:SenderFrameworkLocalizedString(@"error_camera_not_available_go_to_settings", nil), nil];
    [cameraNotAvailiableAlert show];
}

@end

@interface CameraManager (UsePhotoViewControllerDelegate) <UsePhotoViewControllerDelegate>
@end

@implementation CameraManager (UsePhotoViewControllerDelegate)

- (void)usePhotoViewControllerDidCancel:(UsePhotoViewController *)controller
{
    [self backButtonClick:nil];
}

- (void)usePhotoViewControllerDidDismiss:(UsePhotoViewController *)controller
{
    if ([self.delegate respondsToSelector:@selector(cameraManagerDidFinishWithError:)])
        [self.delegate cameraManagerDidFinishWithError:nil];
}
- (void)usePhotoViewControllerDidAccept:(UsePhotoViewController *)controller
{
    [self usePhotoButtonClick:nil];
}

@end
