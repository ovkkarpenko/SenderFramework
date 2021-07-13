//
//  MainButtonCell.m
//  SENDER
//
//  Created by Roman Serga on 20/7/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "MainButtonCell.h"
#import "PBConsoleConstants.h"

@implementation MainActionModel

-(MainActionModel *)initWithName:(NSString *)name image:(UIImage *)image tapHandler:(void (^)())tapHandler
{
    self = [super init];
    if (self)
    {
        self.localizedName = name;
        self.image = image;
        self.tapHandler = tapHandler;
    }
    return self;
}

@end

@interface MainButtonCell ()

    @property (nonatomic, weak) IBOutlet UIView * imageBackground;

@end

@implementation MainButtonCell

+(CGSize)templateSizeForDeviceType:(DeviceType)device
{
    CGSize templateSize;
    switch (device) {
        case DeviceTypeIphone4:
        case DeviceTypeIphone5:
            templateSize = CGSizeMake(92.0f, 89.0f);
            break;
        case DeviceTypeIphone6:
            templateSize = CGSizeMake(101.0f, 110.0f);
            break;
        case DeviceTypeIphone6p:
            templateSize = CGSizeMake(106.0f, 110.0f);
            break;
        default:
            templateSize = CGSizeMake(106.0f, 110.0f);
            break;
    }
    return templateSize;
}

+(CGFloat)defaultTitleForDeviceType:(DeviceType)device
{
    return 30.0f;
}


-(void)layoutSubviews
{
    [super layoutSubviews];
    [self performSelector:@selector(customizeImageBackground) withObject:nil afterDelay:0.01f];
}

-(void)setImage:(UIImage *)image
{
    self.mainImage.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.mainImage.contentMode = UIViewContentModeScaleAspectFit;

    [self setNeedsLayout];
}

-(void)customizeImageBackground
{
    self.imageBackground.layer.borderWidth = 1.0f;
    self.imageBackground.layer.cornerRadius = self.imageBackground.frame.size.width / 2;
}

-(void)setTitleText:(NSString *)titleText
{
    self.title.text = titleText;
}

-(void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    self.title.textColor = self.tintColor;
    self.imageBackground.layer.borderColor = self.tintColor.CGColor;
}

-(void)setImageColor:(UIColor *)tintColor
{
    self.mainImage.tintColor = tintColor;
}

-(void)customizeWithModel:(MainActionModel *)model
{
    [self setTitleText:model.localizedName];
    [self setImage:model.image];
}

@end
