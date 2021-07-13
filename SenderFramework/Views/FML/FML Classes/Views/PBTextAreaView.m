//
//  PBTextAreaView.m
//  SENDER
//
//  Created by Eugene Gilko on 5/27/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "PBTextAreaView.h"
#import "ConsoleCaclulator.h"
#import "MainContainerModel.h"

@implementation PBTextAreaView

@dynamic viewModel;

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];

    self.viewModel = submodel;
    float startX = 0;
    if (mainRect.origin.x > 0)
        startX = mainRect.origin.x;
    
    self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, 60.0);
    self.backgroundColor = [UIColor clearColor];
    
    _inputTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, mainRect.size.width, 60.0)];
    
    [_inputTextView setFont:[PBConsoleConstants inputTextFieldFontStyle:self.viewModel.fontStyle
                                                                andSize:self.viewModel.fontSize]];

    _inputTextView.delegate = self;
    
    
    if (self.viewModel.color) {
        [_inputTextView setTextColor:[PBConsoleConstants colorWithHexString:self.viewModel.color]];
    }

    if (self.viewModel.b_size) {
        _inputTextView.layer.borderWidth = [self.viewModel.b_size floatValue];
    }
    if (self.viewModel.b_color) {
        _inputTextView.layer.borderColor = [PBConsoleConstants colorWithHexString:self.viewModel.b_color].CGColor;
    }
    
    if (self.viewModel.b_radius) {
        _inputTextView.layer.cornerRadius = [self.viewModel.b_radius floatValue];
        _inputTextView.layer.masksToBounds=YES;
    }
    else {
        _inputTextView.layer.cornerRadius = 0;
        _inputTextView.layer.masksToBounds = YES;
    }
    
    if (self.viewModel.val.length) {
        self.inputedText =  [self.viewModel.val description];
        _inputTextView.text = self.inputedText;
    }
    
    [self addSubview:_inputTextView];
    
    
    if ([self.viewModel.state isEqualToString:@"invisible"]) {
        self.hidden = YES;
    }
}

- (void)loseFocus
{
    [_inputTextView resignFirstResponder];
}

- (BOOL)textViewShouldReturn:(UITextView *)textField
{
    [self loseFocus];
    return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    self.viewModel.val = textView.text;
}

@end
