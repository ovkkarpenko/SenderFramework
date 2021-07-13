//
//  ConsoleCaclulator.m
//  SENDER
//
//  Created by Eugene on 12/26/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "ConsoleCaclulator.h"
#import "PBConsoleConstants.h"
#import <CoreText/CoreText.h>
#import "PBSubviewFacade.h"
#import "MainContainerModel.h"

CGRect CorrectRectWithPaddingList (CGRect sourceRect,NSArray * paddingList)
{
    float yPOS = sourceRect.origin.y + [paddingList[0] integerValue];
    float xPOS = sourceRect.origin.x + [paddingList[3] integerValue];
    float width = sourceRect.size.width - [paddingList[1] integerValue] - [paddingList[3] integerValue];
    sourceRect = CGRectMake(xPOS, yPOS, width, sourceRect.size.height);
    return sourceRect;
}

CGRect CorrectRectWithMargingList (CGRect sourceRect,NSArray * margingList)
{
    float yPOS = sourceRect.origin.y + [margingList[0] integerValue];
    float xPOS = sourceRect.origin.x + [margingList[3] integerValue];
    float width = sourceRect.size.width - [margingList[1] integerValue] - [margingList[3] integerValue];
    sourceRect = CGRectMake(xPOS, yPOS, width, sourceRect.size.height);
    return sourceRect;
}

void SettingBorderForView (UIView * operandView,MainContainerModel * viewModel)
{
    if (viewModel.b_size) {
        operandView.layer.borderWidth = [viewModel.b_size floatValue];
        
        if (viewModel.b_color) {
            operandView.layer.borderColor = [PBConsoleConstants colorWithHexString:viewModel.b_color].CGColor;
        }
    }
    
    if (viewModel.b_radius) {
        
        operandView.layer.cornerRadius = [viewModel.b_radius floatValue];
        operandView.clipsToBounds = YES;
    }
}

NSMutableAttributedString * AtributedTitleString(NSString * date,NSString * title, NSString * chatName)
{
    NSMutableArray * info = [[NSMutableArray alloc] init];
    
    [info addObject:[NSDictionary dictionaryWithObjectsAndKeys:[PBConsoleConstants timeMarkerFont], @"font", date, @"string", [PBConsoleConstants colorGrey], @"colour", nil]];
    [info addObject:[NSDictionary dictionaryWithObjectsAndKeys:[PBConsoleConstants inputTextFieldFontStyle:nil andSize:12], @"font", title, @"string",[PBConsoleConstants colorGrey], @"colour", nil]];
    [info addObject:[NSDictionary dictionaryWithObjectsAndKeys:[PBConsoleConstants inputTextFieldFontStyle:@"-Bold" andSize:12], @"font", chatName, @"string", [PBConsoleConstants colorGrey], @"colour", nil]];
    
    return BuildStringFromArray(info);
}

void AssignAtributes (NSMutableAttributedString * targetString,int rangeStart, int rangeEnd,UIColor * colour,UIFont * font)
{
    [targetString addAttribute:NSFontAttributeName value:font range:NSMakeRange(rangeStart, rangeEnd)];
    [targetString addAttribute:NSForegroundColorAttributeName value:colour range:NSMakeRange(rangeStart, rangeEnd)];
}

NSMutableAttributedString * BuildStringFromArray (NSArray * info)
{
    NSString * infoString = @"";
    
    for (NSDictionary * partInfo in info) {
        if ([partInfo valueForKey:@"string"])
            infoString = [infoString stringByAppendingString:[partInfo valueForKey:@"string"]];
    }
    
    NSMutableAttributedString * finalString = [[NSMutableAttributedString alloc] initWithString:infoString];
    int stepPosition = 0;
    
    for (NSDictionary * partInfo in info) {
        int endPos = (int)[[partInfo objectForKey:@"string"] length];
        AssignAtributes (finalString,stepPosition, endPos,[partInfo objectForKey:@"colour"],[partInfo objectForKey:@"font"]);
        stepPosition += [[partInfo valueForKey:@"string"] length];
    }
    
    return finalString;
}

NSMutableAttributedString * MakeUnderLineAtributedString(NSString * sourceString, UIFont * font, UIColor * color)
{
    NSMutableAttributedString * finalString = [[NSMutableAttributedString alloc] initWithString:sourceString];
    [finalString addAttribute:(NSString *)kCTUnderlineStyleAttributeName
                      value:[NSNumber numberWithInt:kCTUnderlineStyleSingle]
                      range:(NSRange){0,[finalString length]}];
    
    [finalString addAttribute:NSFontAttributeName
                      value:font
                      range:(NSRange){0,[finalString length]}];
    
    [finalString addAttribute:NSForegroundColorAttributeName
                        value:color
                        range:(NSRange){0,[finalString length]}];
    
    return finalString;
}

BOOL RebuildWidthForRowInModel (MainContainerModel * model,float width)
{
    if (model.submodels) {
        
        if (model.submodels.count == 1) {
            if (!((MainContainerModel *)model.submodels[0]).w)
                ((MainContainerModel *)model.submodels[0]).w = [NSNumber numberWithFloat:width];
        }
        else {
            
            float topTotalWeight = 0;
            
            for (MainContainerModel * subModel in model.submodels) {
                
                if ([model.state isEqualToString:@"gone"] || [subModel.state isEqualToString:@"gone"]) {
                    // NOTHING TO DO HERE
                }
                else {
                    if (subModel.w) {
                        if (subModel.mg) {
                            width -= (float)[subModel.mg[1] floatValue];
                            width -= (float)[subModel.mg[3] floatValue];
                        }
                        width -= (float)[subModel.w floatValue];
                    }
                    else {
                        topTotalWeight += (int)[subModel.weight integerValue];
                    }
                }
            }
            
            for (MainContainerModel * subModel in model.submodels) {

                if ([model.state isEqualToString:@"gone"] || [subModel.state isEqualToString:@"gone"]) { // NOTHING TO DO HERE
                }
                else {
                    if (!subModel.w) {
                
                        float weightFloat = ([subModel.weight floatValue] / topTotalWeight) * 100.0f;
                        
                        subModel.w = [NSNumber numberWithFloat:lroundf(width * (weightFloat/100.0))];
                        
                        //ceil() floor() lroundf()
                    }
                }
            }
        }
        
    }
    
    return YES;
}

void SetFormLabelAligment(UILabel * textView,MainContainerModel * viewModel)
{
    if ([viewModel.talign isEqualToString:@"center"]) {
        [textView setTextAlignment:NSTextAlignmentCenter];
    }
    else if ([viewModel.talign isEqualToString:@"right"]) {
        [textView setTextAlignment:NSTextAlignmentRight];
    }
    
    if (viewModel.color) {
        textView.textColor = [PBConsoleConstants colorWithHexString:viewModel.color];
    }
}

void SetFormTextAligment(UITextView * textView,MainContainerModel * viewModel)
{
    if ([viewModel.talign isEqualToString:@"center"]) {
        [textView setTextAlignment:NSTextAlignmentCenter];
    }
    else if ([viewModel.talign isEqualToString:@"right"]) {
        [textView setTextAlignment:NSTextAlignmentRight];
    }
    
    if (viewModel.color) {
        textView.textColor = [PBConsoleConstants colorWithHexString:viewModel.color];
    }
}

void SetFormTextFieldAligment(UITextField * textView,MainContainerModel * viewModel)
{
    if ([viewModel.talign isEqualToString:@"center"]) {
        [textView setTextAlignment:NSTextAlignmentCenter];
    }
    else if ([viewModel.talign isEqualToString:@"right"]) {
        [textView setTextAlignment:NSTextAlignmentRight];
    }
    
    if (viewModel.color) {
        textView.textColor = [PBConsoleConstants colorWithHexString:viewModel.color];
    }
}

void VerticalAlignSubviewInview(UIView * mainView)
{
    for (PBSubviewFacade * subView in mainView.subviews) {
        
        MainContainerModel * viewModel = subView.viewModel;
        
        if ([viewModel.valign isEqualToString:@"bottom"]) {
            
            CGRect viewRect = subView.frame;
            viewRect.origin.y = mainView.frame.size.height - subView.frame.size.height;
            subView.frame = viewRect;
            
        }
        else if ([viewModel.valign isEqualToString:@"center"]) {
            
            CGRect viewRect = subView.frame;
            viewRect.origin.y = (mainView.frame.size.height - subView.frame.size.height)/2;
            subView.frame = viewRect;
            
        }
    }
}

void HorisontalAlignSubviewInview(ColVewContainer * mainView)
{
    CGRect rect  = mainView.frame;
    for (PBSubviewFacade * subView in mainView.subviews) {
        
        if (subView.viewModel) {
          
            MainContainerModel * viewModel = subView.viewModel;
            
            if ([viewModel.halign isEqualToString:@"right"]) {
                
                CGRect viewRect = subView.frame;
                
                if (viewModel.w) {
                    viewRect.size.width = (int)[viewModel.w integerValue];
                }
                
                viewRect.origin.x = rect.size.width - viewRect.size.width;
                subView.frame = viewRect;
                
            }
            else if ([viewModel.halign isEqualToString:@"center"]) {
                
                CGRect viewRect = subView.frame;
                if (viewModel.w) {
                    viewRect.size.width = (int)[viewModel.w integerValue];
                }

                viewRect.origin.x = (rect.size.width  - viewRect.size.width)/2;
                subView.frame = viewRect;
                
            }
        }
    }
}
