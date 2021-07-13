//
//  StickerView.h
//  SENDER
//
//  Created by Roman Serga on 23/1/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StickerButton.h"

@protocol StickerViewDelegate <NSObject>

-(void)stickerViewDidOpenedStickerPack;
-(void)stickerViewDidSelectedSticker:(NSString*)stickerID;

@end

@interface StickerView : UIView

@property (nonatomic, weak) id<StickerViewDelegate> delegate;

-(void)goBack;

@end
