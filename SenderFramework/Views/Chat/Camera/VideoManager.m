//
//  VideoManager.m
//  SENDER
//
//  Created by Eugene on 12/11/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "VideoManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import <AVFoundation/AVFoundation.h>
#import <SenderFramework/SenderFramework-Swift.h>

@implementation VideoManager
{
    __weak UIViewController * parentController;
    MPMoviePlayerController * moviePlayer;
    UIImage * finalImage;
    NSURL * videoOutURL;
    NSData * outPutData;
}

- (id)initWithParentController:(UIViewController *)controller
{
    if (self = [super init]) {
        parentController = controller;
    }
    return self;
}

- (void)showCamera
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    picker.mediaTypes = @[(NSString *) kUTTypeMovie];
    [parentController presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSURL * videoURL = info[UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    AVAsset * video = [AVAsset assetWithURL:videoURL];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:video
                                                                            presetName:AVAssetExportPresetPassthrough];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeMPEG4;
    NSURL * tmpDirectory = MWSenderFileManager.shared.tmpDirectory;
    NSString * fileName = NSProcessInfo.processInfo.globallyUniqueString;
    NSURL * outURL = [[tmpDirectory URLByAppendingPathComponent:fileName] URLByAppendingPathExtension:@"mp4"];
    exportSession.outputURL = outURL;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSData * videoData = [NSData dataWithContentsOfURL:outURL];
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:outURL
                                                    options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @YES}];
        if (!videoData || !asset)
        {
            NSError * videoError = [[NSError alloc] initWithDomain:@"Cannot get recorded video"
                                                              code:1
                                                          userInfo:nil];
            if ([self.delegate respondsToSelector:@selector(videoManager:didFinishWithError:)])
                [self.delegate videoManager:self didFinishWithError:videoError];
            return;
        }
        NSTimeInterval durationOfFile = CMTimeGetSeconds(asset.duration);
        [[NSFileManager defaultManager] removeItemAtURL:outURL error:nil];
        if ([self.delegate respondsToSelector:@selector(videoManager:didFinishPickingVideoWithData:duration:)])
            [self.delegate videoManager:self didFinishPickingVideoWithData:videoData duration:durationOfFile];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if ([self.delegate respondsToSelector:@selector(videoManager:didFinishWithError:)])
        [self.delegate videoManager:self didFinishWithError:nil];
}

@end
