//
//  MainButtonCell.h
//  SENDER
//
//  Created by Roman Serga on 20/7/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DeviceType)
{
    DeviceTypeIphone4,
    DeviceTypeIphone5,
    DeviceTypeIphone6,
    DeviceTypeIphone6p,
};

@interface MainActionModel : NSObject

@property (nonatomic, strong) NSString * localizedName;
@property (nonatomic, strong) UIImage * image;
@property (nonatomic, copy) void (^tapHandler)();

-(MainActionModel *)initWithName:(NSString *)name image:(UIImage *)image tapHandler:(void (^)())tapHandler;

@end

@interface MainButtonCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView * mainImage;
@property (nonatomic, weak) IBOutlet UILabel * title;

+(CGSize)templateSizeForDeviceType:(DeviceType)device;
+(CGFloat)defaultTitleForDeviceType:(DeviceType)device;
-(void)setImage:(UIImage *)image;
-(void)setTitleText:(NSString *)titleText;
-(void)customizeWithModel:(MainActionModel *)model;

@end
