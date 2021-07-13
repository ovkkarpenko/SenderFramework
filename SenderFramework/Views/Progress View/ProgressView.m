//
//  ProgressView.m
//  SENDER
//
//  Created by Roman Serga on 18/3/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "ProgressView.h"
#import "PBConsoleConstants.h"

@interface ProgressView ()

@property (nonatomic, weak) IBOutlet UILabel * descriptionLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView * spinner;

@end

@implementation ProgressView

- (void)setTintColor:(UIColor *)tintColor
{
    self.descriptionLabel.textColor = tintColor;
    self.spinner.color = tintColor;
}

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text
{
    self = [super initWithFrame:frame];
    if (self)
    {
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        self = [NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"ProgressView" owner:nil options:nil][0];
        
        self.descriptionLabel.font = [[SenderCore sharedCore].stylePalette dateMarkerFont];
        self.descriptionLabel.text = text;
        
        if (!CGRectEqualToRect(frame, CGRectZero))
            self.frame = frame;

        self.layer.cornerRadius = 10.0f;

        self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        [self.spinner startAnimating];
        self.tintColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
        [self layoutIfNeeded];
    }
    return self;
}

- (instancetype)initWithText:(NSString *)text
{
    self = [self initWithFrame:CGRectZero text:text];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame text:@""];
    return self;
}

- (void)setText:(NSString *)text
{
    self.descriptionLabel.text = text;
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [self layoutIfNeeded];
}

- (NSString *)text
{
    return self.descriptionLabel.text;
}

@end
