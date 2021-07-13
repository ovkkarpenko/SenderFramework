//
//  QRScanView.h
//  SENDER
//
//  Created by Roman Serga on 23/1/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol QRScannerDelegate <NSObject>

-(void)scanViewDidDecodedData:(NSString*)data;

@optional
-(void)scanViewDidFailedToStart;

@end

@interface QRScanView : UIView <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, weak) IBOutlet id<QRScannerDelegate> delegate;

- (void)startRunning;
- (void)stopRunning;

@end
