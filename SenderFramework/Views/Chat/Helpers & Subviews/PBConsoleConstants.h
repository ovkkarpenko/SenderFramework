//
//  PBConsoleConstants.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/22/14.
//  Copyright (c) 2014 Eugene Gilko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MainContainerModel;

@interface PBConsoleConstants : NSObject

extern NSString * const PBAddSelectViewToScene;
extern NSString * const PBRemoveViewFromScene;
extern NSString * const PBChatSendValueNotification;
extern NSString * const PBChatLoseFocus;
extern NSString * const PBChatButtonModeNotification;

//FONTS
+ (UIFont *)headerFont;
+ (UIFont *)titleFont;
+ (UIFont *)inputTextFieldFont;
+ (UIFont *)placeholderTextFieldFont;
+ (UIFont *)timeMarkerFont;
+ (UIFont *)dateMarkerFont;
+ (UIFont *)inputTextFieldFontStyle:(NSString *)style andSize:(float)size;

//COLORS

+ (UIColor *)colorDeepBlue;
+ (UIColor *)colorBorderGrey;
+ (UIColor *)colorGrey;
+ (UIColor *)colorWithHexString:(NSString *)str;
+ (UIColor *)colorGreenSelected;
+ (UIColor *)mainBlueColor;
+ (UIColor *)mainTextColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)commonGreyColor;

//MATH FUNCTIONS

+ (BOOL)checkPhoneField:(UITextField *)textField range:(NSRange)range replacementString:(NSString *)string;
+ (BOOL)isNumericINTEGER:(NSString *) testString;
+ (BOOL)isNumericI:(NSString *) testString;
+ (BOOL)checkFloat:(NSString *)string;
BOOL ValidateEmail(NSString * emailForTest);

CGSize CalculateSenderHeaderSize (NSString * text, UIFont * font, float cellWidth);


//GRAPH FUNCTIONS

+ (void)makeTextFieldUnselected:(UITextField *)textField;
+ (void)makeTextFieldSelected:(UITextField *)textField;
+ (void)imageSetRounds:(UIImageView *)imgView;

+ (UIImage *)maskImageWithCustomImage:(UIImage *)image maskImage:(UIImage *)maskImage;
+ (void)settingViewBorder:(UIView *)operandView andModel:(MainContainerModel *)viewModel;
+ (UIImage *)renderViewToImage:(UIView *)view;
+ (void)setSystemButton:(UIButton *)button withText:(NSString *)title orImage:(NSString *)image;
+ (void)setCustomSystemButton:(UIButton *)button
                     withText:(NSString *)title
                      orImage:(NSString *)imageName
                        color:(UIColor *)color;
+ (void)setButtonSelected:(UIButton *)button;
+ (void)setButtonDefault:(UIButton *)button;
+ (void)changePlaceholderIn:(UITextField *)textField toColor:(UIColor *)color;

@end

