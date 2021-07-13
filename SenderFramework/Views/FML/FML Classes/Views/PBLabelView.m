//
//  PBLabelView.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/23/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBLabelView.h"
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import "ConsoleCaclulator.h"
#import "Owner.h"
#import "MainContainerModel.h"
#import "MWFMLStringParser.h"

@implementation PBLabelView
{
    float xStart;
    UILabel * headerText;
}

@dynamic viewModel;

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];

    self.viewModel = submodel;
    
    NSString * valString = [self.viewModel.val description];

    [MWFMLStringParser parseFMLString:valString
                              forChat:self.viewModel.chat
                    completionHandler:^(NSString *parsedString) {
                        [self initWithText:parsedString andRect:mainRect];
                    }];
}

- (void)initWithText:(NSString *)text andRect:(CGRect)mainRect
{
    float startX = 0;
    if (mainRect.origin.x > 0)
        startX = mainRect.origin.x;
        
    self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, 25.0);
    
    float newWidth = mainRect.size.width;// - rightIndent

    [self config:newWidth text:text];
    
    if ([self.viewModel.state isEqualToString:@"invisible"]) {
        self.hidden = YES;
    }
    
    if (self.viewModel.color) {
        headerText.textColor = [PBConsoleConstants colorWithHexString:self.viewModel.color];
    }
    
    if (self.viewModel.bg) {
        headerText.backgroundColor = [PBConsoleConstants colorWithHexString:self.viewModel.bg];
    }
    else {
        headerText.backgroundColor = [UIColor clearColor];
    }
}

- (void)config:(float)mainW text:(NSString *)text
{
    [headerText removeFromSuperview];
    
    UIFont * labelFont = [PBConsoleConstants inputTextFieldFontStyle:self.viewModel.fontStyle andSize:self.viewModel.fontSize];
    CGSize size = CalculateSenderHeaderSize (text, labelFont, mainW);
    
    headerText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, mainW, size.height)];
    [headerText setFont:labelFont];
    headerText.numberOfLines = 0;
    if (![text isKindOfClass:[NSNull class]]) {
        headerText.text = text;
    }
    
    [headerText sizeToFit];
    CGRect rect = self.frame;
    rect.size.height = headerText.frame.size.height;
    self.frame = rect;
    rect.origin.x = rect.origin.y = 0;
    headerText.frame = rect;
    SetFormLabelAligment(headerText,self.viewModel);
    
    [self addSubview:headerText];
}

@end
