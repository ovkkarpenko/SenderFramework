//
//  ConsoleCaclulator.h
//  SENDER
//
//  Created by Eugene on 12/26/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBConsoleConstants.h"
#import "ColVewContainer.h"

CGRect CorrectRectWithPaddingList (CGRect sourceRect,NSArray * paddingList);
CGRect CorrectRectWithMargingList (CGRect sourceRect,NSArray * margingList);
void SettingBorderForView (UIView * operandView,MainContainerModel * viewModel);
void AssignAtributes (NSMutableAttributedString * targetString,int rangeStart, int rangeEnd,UIColor * colour,UIFont * font);
NSMutableAttributedString * MakeUnderLineAtributedString(NSString * sourceString, UIFont * font, UIColor * color);
NSMutableAttributedString * AtributedTitleString(NSString * date,NSString * title, NSString * chatName);
NSMutableAttributedString * BuildStringFromArray (NSArray * info);
BOOL RebuildWidthForRowInModel (MainContainerModel * model,float width);
void SetFormTextAligment(UITextView * textView,MainContainerModel * viewModel);
void SetFormLabelAligment(UILabel * textView,MainContainerModel * viewModel);
void SetFormTextFieldAligment(UITextField * textView,MainContainerModel * viewModel);
void VerticalAlignSubviewInview(UIView * mainView);
void HorisontalAlignSubviewInview(ColVewContainer * mainView);