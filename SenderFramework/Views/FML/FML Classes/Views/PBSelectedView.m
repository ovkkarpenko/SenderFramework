//
//  PBSelectedView.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/24/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import "PBSelectedView.h"
#import "PBLabelView.h"
#import "ConsoleCaclulator.h"

@implementation PBSelectedView
@dynamic viewModel;

#define kDefaultHeight 40.0

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];

    self.viewModel = submodel;
    float startX = 0;
    if (mainRect.origin.x > 0)
        startX = mainRect.origin.x;
    
    UIFont * cellFont;
    
    if (submodel.fontSize && submodel.fontSize > 0) {
        cellFont = [PBConsoleConstants inputTextFieldFontStyle:submodel.fontStyle andSize:submodel.fontSize];
        CGSize size = CalculateSenderHeaderSize (@"te", cellFont, mainRect.size.width - 30);
        
        self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, (size.height > kDefaultHeight) ? size.height:kDefaultHeight);
    }
    else {
        cellFont = [PBConsoleConstants placeholderTextFieldFont];
        self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, kDefaultHeight);
    }

    self.backgroundColor = [UIColor clearColor];
    
    _inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, mainRect.size.width, (self.frame.size.height > kDefaultHeight) ? self.frame.size.height:kDefaultHeight)];// - leftIndent - rightIndent
    
    [_inputTextField setFont:cellFont];
    [_inputTextField setPlaceholder:self.viewModel.hint];
    [PBConsoleConstants makeTextFieldUnselected:_inputTextField];
    _inputTextField.userInteractionEnabled = NO;
    _inputTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    UIImageView * arrow = [[UIImageView alloc] initWithImage:[UIImage imageFromSenderFrameworkNamed:@"arrow_black_small"]];
    [self addSubview:arrow];
    arrow.frame = CGRectMake(mainRect.size.width - 15.0, 13.0, arrow.frame.size.width, arrow.frame.size.height);

    UIButton * selectButton = [[UIButton alloc] initWithFrame:_inputTextField.frame];
    [selectButton addTarget:self action:@selector(cellWasSelected) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:selectButton];

    if (self.viewModel.vars.count) {
        
        int x = 0;
        if (self.viewModel.val.length) {
            int j = 0;
            
            for (NSDictionary * vars in self.viewModel.vars) {
                if ([self.viewModel.val isEqualToString:vars[@"v"]]) {
                    x = j;
                    break;
                }
                j++;
            }
        }
       
        _inputTextField.text = [self.viewModel.vars[x][@"t"] description];
        self.viewModel.val = [self.viewModel.vars[x][@"v"] description];
    }
    
    if (self.viewModel.b_size) {
        _inputTextField.layer.borderWidth = [self.viewModel.b_size floatValue];
    }
    if (self.viewModel.b_color) {
        _inputTextField.layer.borderColor = [PBConsoleConstants colorWithHexString:self.viewModel.b_color].CGColor;
    }
    
    if (self.viewModel.b_radius) {
        _inputTextField.layer.cornerRadius = [self.viewModel.b_radius floatValue];
        _inputTextField.layer.masksToBounds=YES;
    }
    else {
        _inputTextField.layer.cornerRadius = 0;
        _inputTextField.layer.masksToBounds = YES;
    }
    
    [self addSubview:_inputTextField];
    
    if ([self.viewModel.state isEqualToString:@"invisible"]) {
        self.hidden = YES;
    }
}

- (void)cellWasSelected
{
    if ([self.delegate respondsToSelector:@selector(selectValueFromValues:forSelectView:)])
        [self.delegate selectValueFromValues:self.viewModel.vars forSelectView:self];
}

- (void)setSelectedValue:(NSDictionary *)selectedValue
{
    _inputTextField.text = [selectedValue[@"t"] description];
    self.viewModel.val = [selectedValue[@"v"] description];

    if (self.viewModel.action) {
        [super doAction:self.viewModel.action];
    }
    else if (self.viewModel.actions) {
        for (NSDictionary * act in self.viewModel.actions) {
            [super doAction:act];
        }
    }
}

@end
