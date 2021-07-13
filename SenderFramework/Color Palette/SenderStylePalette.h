//
//  SenderStylePalette.h
//  SENDER
//
//  Created by Roman Serga on 26/10/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ChatBackgroundImageType) {
    ChatBackgroundImageTypeLightBlur,
    ChatBackgroundImageTypeDarkBlur
};

@interface SenderStylePalette : NSObject

@property (nonatomic, strong) UIFont * headerFont;
@property (nonatomic, strong) UIFont * inputTextFieldFont;
@property (nonatomic, strong) UIFont * placeholderTextFieldFont;
@property (nonatomic, strong) UIFont * timeMarkerFont;
@property (nonatomic, strong) UIFont * dateMarkerFont;

//Common colors

@property (nonatomic, strong) UIColor * mainAccentColor;

@property (nonatomic, strong) UIColor * navigationCommonBarColor;

@property (nonatomic, strong) UIColor * alertColor;

@property (nonatomic, strong) UIColor * mainTextColor;
@property (nonatomic, strong) UIColor * secondaryTextColor;

@property (nonatomic, strong) UIColor * lineColor;
@property (nonatomic, strong) UIColor * actionButtonTitleColor;

@property (nonatomic, strong) UIColor * controllerCommonBackgroundColor;

//Settings

@property (nonatomic, strong) UIColor * commonTableViewBackgroundColor;

//Messages bubbles

@property (nonatomic, strong) UIColor * myMessageBackgroundColor;
@property (nonatomic, strong) UIColor * foreignMessageBackgroundColor;
@property (nonatomic, strong) UIColor * encryptedMessageBackgroundColor;
@property (nonatomic, strong) UIColor * encryptedOwnerMessageBackgroundColor;

@property (nonatomic, strong) UIColor * foreignMessageBorderColor;
@property (nonatomic, strong) UIColor * foreignEncryptedMessageBorderColor;

@property (nonatomic, strong) UIColor * messageDetailsColor;

//WelcomeViewController colors

@property (nonatomic, strong) UIColor * welcomeViewControllerProgressColor;
@property (nonatomic, strong) UIImage * welcomeViewControllerLogo;
@property (nonatomic, strong) UIImage * welcomeViewControllerBackgroundImage;

//UserProfileViewController colors

@property (nonatomic, strong) UIColor * bitcoinColor;

//ChatViewController

@property (nonatomic, strong) UIColor * chatNotificationBackgroundColor;
@property (nonatomic, strong) UIColor * chatNotificationTextColor;

@property (nonatomic) ChatBackgroundImageType chatBackgroundImageType;

- (UIFont *)inputTextFieldFontStyle:(NSString *)style andSize:(float)size;
- (UIColor *)colorWithHexString:(NSString *)str;
- (UIColor *)randomColor;


/*
 * By default sets lineColor as textColor.
 * Override this method for custom behaviour
 */

- (NSAttributedString *)placeholderWithString:(NSString *)string;

/*
 * By default sets navigationCommonBarColor as barTintColor,
 * mainAccentColor as tintColor and makes navigationBar translucent.
 * Override this method for custom behaviour
 */
- (void)customizeNavigationBar:(UINavigationBar *)navigationBar;

/*
 * By default, sets plain back button without text.
 * Override this method for custom behaviour
 */
- (void)customizeNavigationItem:(UINavigationItem *)navigationItem;

@end
