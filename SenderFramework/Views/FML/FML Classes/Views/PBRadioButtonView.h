//
//  PBRadioButtonView.h
//  Sender
//
//  Created by Eugene Gilko on 9/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBCheckBoxModel.h"

@class PBRadioButtonView;

@protocol PBRadioViewDelegate <NSObject>

- (void)pushOnRadio:(PBRadioButtonView *)controller didFinishEnteringItem:(PBCheckBoxModel *)model;

@end

@interface PBRadioButtonView : UIView
{
    UIImageView * boxImage;
}

- (id)initWithModel:(PBCheckBoxModel *)model andRect:(CGRect)rect;
- (void)changeViewMode:(bool)mode;

@property (nonatomic, assign)   id<PBRadioViewDelegate> delegate;
@property (nonatomic, strong) PBCheckBoxModel * boxModel;

@end