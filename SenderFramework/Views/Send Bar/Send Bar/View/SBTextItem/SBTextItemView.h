//
//  SBTextItemView.h
//  SENDER
//
//  Created by Roman Serga on 9/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBItemView.h"

@class SBTextItemView;

@protocol SBTextItemViewDelegate <SBItemViewDelegate>

@required

-(void)textItemView:(SBTextItemView *)textItem didChangeHeight:(CGFloat)height;
-(void)textItemView:(SBTextItemView *)textItem didPressSendWithText:(NSString *)text;
-(BOOL)textItemViewShouldBeginEditing:(SBTextItemView *)textItem;

@optional

-(void)textItemViewDidBeginEditing:(SBTextItemView *)textItem;
-(void)textItemViewDidEndEditing:(SBTextItemView *)textItem;
-(void)textItemViewDidType:(SBTextItemView *)textItem;

@end

@interface SBTextView : UITextView


@end

@interface SBTextItemView : SBItemView <UITextViewDelegate>

@property (nonatomic, weak) id<SBTextItemViewDelegate> delegate;

-(instancetype)initWithFrame:(CGRect)frame andItemModel:(BarItem *)itemModel shouldExpand:(BOOL)shouldExpand bigButton:(BOOL)shouldBeBig;
@property (nonatomic, weak) IBOutlet SBTextView *inputField;
@property (nonatomic, strong) UIView * emojiInputView;
@property (nonatomic) BOOL enterEmoji;
@property (nonatomic, strong) NSString * text;

@end
