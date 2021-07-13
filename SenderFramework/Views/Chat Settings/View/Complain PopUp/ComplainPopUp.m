//
//  ComplainPopUp.m
//  SENDER
//
//  Created by Eugene on 4/15/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "ComplainPopUp.h"

@interface ComplainPopUp()
{
    IBOutlet UILabel * title;
    IBOutlet UITextView * textView;
    IBOutlet UIButton * sendBtt;
    IBOutlet UIButton * cancelBtt;
}

@end

@implementation ComplainPopUp

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        self = [NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"ComplainPopUp" owner:nil options:nil][0];
        title.text = SenderFrameworkLocalizedString(@"complaint_reason_ios", nil);
        [sendBtt setTitle:SenderFrameworkLocalizedString(@"send", nil) forState:UIControlStateNormal];
        [cancelBtt setTitle:SenderFrameworkLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
        [self customizeAppearence];
    }
    return self;
}

-(void)customizeAppearence
{
    self.layer.cornerRadius = 8.0f;
    self.layer.masksToBounds = YES;
    textView.layer.borderWidth = 1.0;
    textView.layer.borderColor = [[SenderCore sharedCore].stylePalette.lineColor colorWithAlphaComponent:0.3].CGColor;
    textView.layer.cornerRadius = 6.0;
    textView.layer.masksToBounds = YES;
    
    [textView becomeFirstResponder];
}

- (IBAction)sendReport:(id)sender
{
    [self callDelegate];
}

- (IBAction)cancellProcess:(id)sender
{
    textView.text = @"";
    [self callDelegate];
}

- (void)callDelegate
{
    [self endEditing:YES];
    [self.delegate complainPopUpDidFinishEnteringText:textView.text];
}

@end
