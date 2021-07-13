//
//  QRScanView.m
//  SENDER
//
//  Created by Roman Serga on 23/1/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "QRScanView.h"

@interface QRScanView ()

@property (nonatomic, strong) AVCaptureSession * captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;

@end

@implementation QRScanView

-(void)layoutSubviews
{
    [super layoutSubviews];
    [_previewLayer setFrame:self.layer.bounds];
}

- (void)configureView
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus != AVAuthorizationStatusAuthorized)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 if(granted)
                 {
                    [self showCamera];
                 }
                 else
                 {
                     if ([self.delegate respondsToSelector:@selector(scanViewDidFailedToStart)])
                         [self.delegate scanViewDidFailedToStart];
                     return;
                 }
             });
         }];
    }
    else {
        [self showCamera];
    }
}

- (void)showCamera
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        NSError * error;
        AVCaptureDevice * captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        _captureSession = [[AVCaptureSession alloc]init];
        [_captureSession addInput:input];
        AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
        [_captureSession addOutput:output];
        dispatch_queue_t dispatchQueue;
        dispatchQueue = dispatch_queue_create("QRScanViewQueue", NULL);
        [output setMetadataObjectsDelegate:self queue:dispatchQueue];
        [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode,
                AVMetadataObjectTypeCode39Code,
                AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeUPCECode]];
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [_previewLayer setFrame:self.layer.bounds];
        
        [self.layer addSublayer:_previewLayer];
        
        [_captureSession startRunning];
    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects != nil && [metadataObjects count] > 0)
    {
        AVMetadataMachineReadableCodeObject * metaData = metadataObjects[0];
        NSString * type = [metaData type];
        if ([type isEqualToString:AVMetadataObjectTypeQRCode] ||
            [type isEqualToString:AVMetadataObjectTypeCode39Code] ||
            [type isEqualToString:AVMetadataObjectTypeCode128Code] ||
            [type isEqualToString:AVMetadataObjectTypeEAN13Code] ||
            [type isEqualToString:AVMetadataObjectTypeUPCECode])
        {
            [self stopRunning];
            _captureSession = nil;
            NSString * dataFromQR = [metaData stringValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate scanViewDidDecodedData:dataFromQR];
            });
        }
    }
}

-(void)startRunning
{
    if (!_captureSession)
        [self configureView];
    else
        [_captureSession startRunning];
}

-(void)stopRunning
{
    [_captureSession stopRunning];
}

@end
