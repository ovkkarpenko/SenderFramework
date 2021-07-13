//
//  PBCheckBoxView.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/28/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import "PBCheckBoxView.h"
#import "UIImage+animatedGIF.h"
#import "PBConsoleConstants.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation PBCheckBoxView
{
    UIImageView * imgView;
}

- (id)initWithModel:(PBCheckBoxModel *)model andRect:(CGRect)rect
{
        if (model.imgLinkl.length) {
            if ((self = [super initWithFrame:CGRectMake(0, rect.origin.y, rect.size.width, 125.0)])) {
                
                 [self configWithImg:rect setupWithModel:model];
            }
        }
        else {
             if ((self = [super initWithFrame:CGRectMake(0, rect.origin.y, rect.size.width, 25.0)])) {
                 [self config:rect setupWithModel:model];
             }
        }
    
    return self;
}

- (void)config:(CGRect)mainRect setupWithModel:(PBCheckBoxModel *)model
{
    self.boxModel = model;
    
    boxImage = [[UIImageView alloc] initWithImage:[self imageForBox]];
    
    boxImage.frame = CGRectMake(0, 5, boxImage.frame.size.width, boxImage.frame.size.height);
    
    [self addSubview:boxImage];
    
    CGSize size = CalculateSenderHeaderSize (model.title, [PBConsoleConstants inputTextFieldFont], self.frame.size.width - boxImage.frame.size.width - 10.0f);
    
    UITextView * headerText = [[UITextView alloc] initWithFrame:CGRectMake(boxImage.frame.size.width + 10.0f, 0.0f, size.width + 10.0f, size.height)];
    headerText.backgroundColor = [UIColor clearColor];
    
    [headerText setFont:[PBConsoleConstants inputTextFieldFont]];
    
    if (![model.title isKindOfClass:[NSNull class]]) {
        headerText.text = model.title;
    }
    
    [headerText setEditable:NO];
    [headerText setScrollEnabled:NO];
    headerText.userInteractionEnabled = NO;
    headerText.dataDetectorTypes = UIDataDetectorTypeAll;
    [headerText sizeToFit];
    [self addSubview:headerText];
    CGRect rect = self.frame;
    rect.size.height = headerText.frame.size.height;
    self.frame = rect;
    rect.origin.y = 0;
    UIButton * button = [[UIButton alloc] initWithFrame:rect];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(pushTheCell) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
}


- (void)configWithImg:(CGRect)mainRect setupWithModel:(PBCheckBoxModel *)model
{
    self.boxModel = model; 
    boxImage = [[UIImageView alloc] initWithImage:[self imageForBox]];
    
    boxImage.frame = CGRectMake(0, 0, boxImage.frame.size.width, boxImage.frame.size.height);
    
    [self addSubview:boxImage];
    
    CGSize size = CalculateSenderHeaderSize (model.title, [PBConsoleConstants inputTextFieldFont], self.frame.size.width);
    
    UITextView * headerText = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, size.height)];
    headerText.backgroundColor = [UIColor clearColor];
    
    [headerText setFont:[PBConsoleConstants inputTextFieldFont]];
    
    if (![model.title isKindOfClass:[NSNull class]]) {
        headerText.text = model.title;
    }
    
    [headerText setEditable:NO];
    [headerText setScrollEnabled:NO];
    headerText.userInteractionEnabled = NO;
    headerText.dataDetectorTypes = UIDataDetectorTypeAll;
    [headerText sizeToFit];
    [self addSubview:headerText];
    CGRect rect = self.frame;
    rect.size.height = headerText.frame.size.height;
    self.frame = rect;
    rect.origin.y = 0;

    rect = self.frame;
    if (rect.size.height < headerText.frame.size.height) {
        rect.size.height = headerText.frame.size.height;
        self.frame = rect;
    }
    
    imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 35, 50, 80)];
    [self addSubview:imgView];
    [imgView sd_setImageWithURL:[NSURL URLWithString:self.boxModel.imgLinkl]];
    
    UIButton * button = [[UIButton alloc] initWithFrame:rect];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(pushTheCell) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
}

- (void)changeViewMode:(bool)mode
{
    self.boxModel.selected = mode;
    boxImage.image = [self imageForBox];
}

- (IBAction)pushTheCell
{
    [self.delegate pushOnCheckBox:self didFinishEnteringItem:self.boxModel];
}

- (UIImage *)imageForBox
{
    if (self.boxModel.selected) {
        return [UIImage imageFromSenderFrameworkNamed:@"select_checkbox"];
    }
    return [UIImage imageFromSenderFrameworkNamed:@"unselect_checkbox"];
}

@end


