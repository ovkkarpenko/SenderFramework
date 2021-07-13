//
//  PBCheckBoxView.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/28/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBCheckBoxModel.h"

@class PBCheckBoxView;

@protocol PBCheckBoxViewDelegate <NSObject>

- (void)pushOnCheckBox:(PBCheckBoxView *)controller didFinishEnteringItem:(PBCheckBoxModel *)model;

@end

@interface PBCheckBoxView : UIView
{
    UIImageView * boxImage;
}

- (id)initWithModel:(PBCheckBoxModel *)model andRect:(CGRect)rect;
- (void)changeViewMode:(bool)mode;

@property (nonatomic, assign)   id<PBCheckBoxViewDelegate> delegate;
@property (nonatomic, strong) PBCheckBoxModel * boxModel;

@end
