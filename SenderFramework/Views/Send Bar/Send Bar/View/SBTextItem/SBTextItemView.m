//
//  SBTextItemView.m
//  SENDER
//
//  Created by Roman Serga on 9/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "SBTextItemView.h"
#import "SBItemView_protected.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "ServerFacade.h"
#import "NSString+PBMessages.h"

#define actionButtonDefaultWidth 45.0f
#define maxTextViewHeight 133.0f
#define minTextViewHeight 37.0f

@interface SBTextView()

@property (nonatomic) BOOL enterEmoji;
@property (nonatomic, strong) UIView * emojiInputView;

@end

@implementation SBTextView

//-(UIView *)inputView
//{
//    return self.enterEmoji ? self.emojiInputView : nil;
//}

@end

@interface SBTextItemView ()
{
    CGFloat heightBeforeAction;
    int typeCounter;
    
    BOOL textViewHidden;
}

@property (nonatomic, weak) IBOutlet UILabel *enterMessageLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputFieldLeftOffset;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputFieldHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *inputFieldWidth;
@property (nonatomic) BOOL bigButton;
@end

@implementation SBTextItemView

@synthesize delegate;

-(instancetype)initWithFrame:(CGRect)frame andItemModel:(BarItem *)itemModel
{
    return [self initWithFrame:frame andItemModel:itemModel shouldExpand:NO bigButton:NO];
}

-(instancetype)initWithFrame:(CGRect)frame
                andItemModel:(BarItem *)itemModel
                shouldExpand:(BOOL)shouldExpand
                   bigButton:(BOOL)shouldBeBig
{
    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
    self = [NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"SBTextItemView" owner:nil options:nil][0];
    if (self)
    {
        self.itemModel = itemModel;
        self.inputField.scrollsToTop = NO;
        self.inputField.textColor = [UIColor blackColor];
        self.bigButton = shouldBeBig;
        textViewHidden = !shouldExpand;
        [self customizeTextViewForFrame:frame setHidden:textViewHidden];
        
        self.enterMessageLabel.text = SenderFrameworkLocalizedString(@"enter_message_ph", nil);
        
        if (!textViewHidden)
            [self customizeViewForTint:self.titleTextColor];
        
        self.frame = frame;
        self.actionButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self layoutIfNeeded];
    }
    return self;
}

-(void)dealloc
{
    self.delegate = nil;
}

-(void)setTitleTextColor:(UIColor *)titleTextColor
{
    [super setTitleTextColor:titleTextColor ? titleTextColor : [[SenderCore sharedCore].stylePalette mainAccentColor]];
    if (!textViewHidden)
        [self customizeViewForTint:self.titleTextColor];
}

-(void)customizeViewForTint:(UIColor *)tintColor
{
    [self.actionButton setTintColor: tintColor];
    [self.inputField setTintColor: tintColor];
}

-(void)setEnterEmoji:(BOOL)enterEmoji
{
    self.inputField.enterEmoji = enterEmoji;
}

-(void)setEmojiInputView:(UIView *)emojiInputView
{
    self.inputField.emojiInputView = emojiInputView;
}

-(void)customizeTextViewForFrame:(CGRect)frame setHidden:(BOOL)hidden
{
    textViewHidden = hidden;
    if (hidden)
    {
        self.inputFieldHeight.constant = 0.0f;
        self.inputFieldWidth.constant = 0.0f;
//        self.inputFieldLeftOffset.constant = 0.0f;
        [self.actionButton setImage:[UIImage new] forState:UIControlStateNormal];
        if ([self.itemModel.icon length])
        {
            _bigButton = YES;
            NSString * scaleSize = _bigButton ? @"@4x":@"@2x";
            
            NSURL * imageURL = [self URLForIconWithLink:self.itemModel.icon withCustomScale:scaleSize];
            [self.actionButton sd_setImageWithURL:imageURL
                                         forState:UIControlStateNormal
                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                
                [self.actionButton setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
            }];

            if (self.itemModel.icon2)
            {
                NSURL * secondImageURL = [self URLForIconWithLink:self.itemModel.icon2];
                [self.actionButton sd_setImageWithURL:secondImageURL
                                             forState:UIControlStateSelected
                                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                    [self customizeViewForTint:[UIColor colorWithPatternImage:self.actionButton.imageView.image]];
                }];
            }
        }
    }
    else
    {
        [self customizeViewForTint:self.titleTextColor];
        [self.actionButton setImage:[[UIImage imageFromSenderFrameworkNamed:@"icSend"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
//        self.inputFieldLeftOffset.constant = 8.0f;
        self.inputFieldHeight.constant = frame.size.height - 16.0f > 0.0f ? frame.size.height - 16.0f : 0.0f;
        self.inputFieldWidth.constant = frame.size.width - 8.0f - actionButtonDefaultWidth > 0.0f ? frame.size.width - 8.0f - actionButtonDefaultWidth : 0.0f;
        [self enableSendButton:[self.inputField hasText]];
    }
}

-(instancetype)initWithItemModel:(BarItem *)itemModel
{
    return [self initWithFrame:CGRectZero andItemModel:itemModel];
}

#pragma mark - UITextView Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(textItemViewShouldBeginEditing:)])
        return [self.delegate textItemViewShouldBeginEditing:self];

    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.enterMessageLabel.hidden = YES;
    self.inputField.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    if ([self.delegate respondsToSelector:@selector(textItemViewDidBeginEditing:)])
        [self.delegate textItemViewDidBeginEditing:self];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    self.inputField.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (!self.inputField.text.length)
        self.enterMessageLabel.hidden = NO;    
    self.inputField.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    if ([self.delegate respondsToSelector:@selector(textItemViewDidEndEditing:)])
        [self.delegate textItemViewDidEndEditing:self];
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self handleUserTyping];
    [self enableSendButton:textView.hasText];
    [self changeHeight];
}

-(void)setText:(NSString *)text
{
    if (!textViewHidden)
    {
        self.inputField.text = text;
        self.inputField.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        [self textViewDidChange:self.inputField];
    }
}

- (NSString *)text
{
    return self.inputField.text;
}

- (NSString *)textInputContextIdentifier
{
    return self.inputField.text;
}

#pragma mark - Height Changing

- (void)changeInputFieldHeight:(CGFloat) newHeight
{
    if (self.inputFieldHeight.constant != newHeight)
    {
        [self.delegate textItemView:self didChangeHeight:newHeight + 16.0f];
        self.inputFieldHeight.constant = newHeight;
        [self layoutIfNeeded];
        if (newHeight <= self.inputField.contentSize.height)
            [self.inputField setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
    }
}

- (void)changeHeight
{
    CGFloat newHeight = minTextViewHeight;
    if ([self.inputField.text length])
    {
        if (self.inputField.contentSize.height < maxTextViewHeight)
        {
            CGSize estimatedSize = [self.inputField sizeThatFits:CGSizeMake(self.inputField.frame.size.width, FLT_MAX)];
            newHeight = estimatedSize.height;
            newHeight = newHeight >= minTextViewHeight ? newHeight : minTextViewHeight;
        }
        else
        {
            newHeight = maxTextViewHeight;
        }
    }
    [self changeInputFieldHeight:newHeight];
}

#pragma mark - Actions

- (IBAction)send:(id)sender
{
    if (textViewHidden)
    {
        if ([self.delegate respondsToSelector:@selector(itemView:didChooseActionsWithData:)])
            [self.delegate itemView:self didChooseActionsWithData:self.itemModel.actionsParsed];
    }
    else if ([self.inputField.text stringByTrimmingWhitespace].length)
    {
        NSString * text = [self.inputField.text copy];
        if ([self.delegate respondsToSelector:@selector(textItemView:didPressSendWithText:)])
            [self.delegate textItemView:self didPressSendWithText:text];
        typeCounter = 6;
        [self enableSendButton:NO];
        [self setText:@""];
    }
}

#pragma mark - Other Methods

- (void)enableSendButton:(BOOL)status
{
    self.actionButton.hidden = !status;
}

- (void)handleUserTyping
{
    if (typeCounter > 4)
    {
        typeCounter = -1;
        if ([self.delegate respondsToSelector:@selector(textItemViewDidType:)])
            [self.delegate textItemViewDidType:self];
    }
    typeCounter ++;
}

@end
