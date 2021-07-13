//
//  SenderStylePalette.m
//  SENDER
//
//  Created by Roman Serga on 26/10/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "SenderStylePalette.h"

@implementation SenderStylePalette

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.headerFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18.0];
        self.inputTextFieldFont = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
        self.placeholderTextFieldFont = [UIFont fontWithName:@"HelveticaNeue" size:15.0];
        self.timeMarkerFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0];
        self.dateMarkerFont = [UIFont fontWithName:@"HelveticaNeue" size:13.0];

        self.mainAccentColor = [self colorWithHexString:@"#6666CC"];
        self.navigationCommonBarColor = [self colorWithHexString:@"#F8F8F8"];
        self.alertColor = [self colorWithHexString:@"#FF3A30"];

        self.mainTextColor = [self colorWithHexString:@"#000000"];
        self.secondaryTextColor = [self colorWithHexString:@"#8F8F94"];

        self.lineColor = [self colorWithHexString:@"#C8C7CC"];
        self.controllerCommonBackgroundColor = [self colorWithHexString:@"#FFFFFF"];

        self.myMessageBackgroundColor = [UIColor colorWithRed:229.0f / 255.0f
                                                        green:229.0f / 255.0f
                                                         blue:246.0f / 255.0f
                                                        alpha:1.0f];
        self.foreignMessageBackgroundColor = [UIColor whiteColor];

        self.encryptedMessageBackgroundColor = [UIColor colorWithRed:255.0f / 255.0f
                                                               green:248.0f / 255.0f
                                                                blue:238.0f / 255.0f
                                                               alpha:1.0f];
        self.encryptedOwnerMessageBackgroundColor = [UIColor colorWithRed:255.0f / 255.0f
                                                                    green:241.0f / 255.0f
                                                                     blue:221.0f / 255.0f
                                                                    alpha:1.0f];

        self.foreignMessageBorderColor = [UIColor colorWithRed:231.0f / 255.0f
                                                         green:238.0f / 255.0f
                                                          blue:240.0f / 255.0f
                                                         alpha:1.0f];
        self.foreignEncryptedMessageBorderColor = [UIColor colorWithRed:255.0f / 255.0f
                                                                  green:241.0f / 255.0f
                                                                   blue:221.0f / 255.0f
                                                                  alpha:1.0f];

        self.messageDetailsColor = [self colorWithHexString:@"#90A4AE"];

        self.bitcoinColor = [self colorWithHexString:@"#FF9800"];

        self.chatBackgroundImageType = ChatBackgroundImageTypeLightBlur;

        self.commonTableViewBackgroundColor = [self colorWithHexString:@"#EFEFF4"];

        self.welcomeViewControllerProgressColor = [UIColor whiteColor];
        self.welcomeViewControllerLogo = [UIImage imageFromSenderFrameworkNamed:@"sender_logo"];
        self.welcomeViewControllerBackgroundImage = [UIImage imageFromSenderFrameworkNamed:@"splash_bg"];

        self.chatNotificationBackgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
        self.chatNotificationTextColor = [UIColor colorWithWhite:1.0f alpha:1.0f];

        self.actionButtonTitleColor = [UIColor whiteColor];
    }
    return self;
}

- (UIFont *)inputTextFieldFontStyle:(NSString *)style andSize:(float)size
{
    NSString * fontName = [[self inputTextFieldFont]fontName];

    if (style) fontName = [fontName stringByAppendingString:style];
    if (size <= 0) size = 15.0;

    return [UIFont fontWithName:fontName size:size];
}

#pragma mark COLORS

- (UIColor *)randomColor
{
    CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (UIColor *)colorWithHexString:(NSString *)str
{
    const char *cStr = [str cStringUsingEncoding:NSASCIIStringEncoding];
    long x = strtol(cStr+1, NULL, 16);
    return [self colorWithHex:(UInt32)x];
}

- (UIColor *)colorWithHex:(UInt32)col
{
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

#pragma - Customization Methods

- (NSAttributedString *)placeholderWithString:(NSString *)string
{
    NSDictionary * attributes = @{NSForegroundColorAttributeName : [SenderCore sharedCore].stylePalette.lineColor};
    return [[NSAttributedString alloc] initWithString:string attributes:attributes];
}

- (void)customizeNavigationBar:(UINavigationBar *)navigationBar
{
    [navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    navigationBar.shadowImage = nil;

    navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [self colorWithHexString:@"#3B3B3B"],
                                          NSFontAttributeName : [UIFont systemFontOfSize:18.0f weight:UIFontWeightSemibold]};
    navigationBar.barTintColor = [SenderCore sharedCore].stylePalette.navigationCommonBarColor;
    navigationBar.tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    [navigationBar setTranslucent:YES];
}

- (void)customizeNavigationItem:(UINavigationItem *)navigationItem
{
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    [navigationItem setBackBarButtonItem:backItem];
}

@end
