
//
//  PBInputTextView.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/22/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBInputTextView.h"
#import "SenderNotifications.h"
#import "Item.h"
#import "NSString(common_addition).h"
#import "ConsoleCaclulator.h"
#import "ParamsFacade.h"
#import "ServerFacade.h"
#import "MainContainerModel.h"
#import "MWFMLStringParser.h"

@implementation PBInputTextView
@dynamic viewModel;

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];

    self.viewModel = submodel;
    float startX = 0;
    if (mainRect.origin.x > 0)
        startX = mainRect.origin.x;

    self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, 40.0);
    
    if (self.viewModel.bg) {
        
        self.backgroundColor = [PBConsoleConstants colorWithHexString:self.viewModel.bg];
    }
    else {
        self.backgroundColor = [UIColor clearColor];
    }
    
    _inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, mainRect.size.width, 40.0)];// - leftIndent - rightIndent
    
    [_inputTextField setFont:[PBConsoleConstants inputTextFieldFontStyle:self.viewModel.fontStyle andSize:self.viewModel.fontSize]];
    
    if (self.viewModel.hint) {
        [_inputTextField setPlaceholder:self.viewModel.hint];
    }
    
    _inputTextField.delegate = self;
    [_inputTextField addTarget:self action:@selector(textFieldDidChanged:) forControlEvents:UIControlEventEditingChanged];

    _inputTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    CGRect rect = _inputTextField.frame;
    
    [_inputTextField sizeToFit];
    
    if (_inputTextField.frame.size.height < 40) {
        rect.size.height = 40;
    }
    else {
        rect.size.height = _inputTextField.frame.size.height;
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
    
    SetFormTextFieldAligment(_inputTextField,self.viewModel);
    
     _inputTextField.frame = rect;
    
    if (self.viewModel.color) {
        [_inputTextField setTextColor:[PBConsoleConstants colorWithHexString:self.viewModel.color]];
        
        if (self.viewModel.hint) {
            
            UIColor * pColor = [[PBConsoleConstants colorWithHexString:self.viewModel.color] colorWithAlphaComponent:0.5f];
            NSAttributedString * str = [[NSAttributedString alloc] initWithString:self.viewModel.hint
                                                                       attributes:@{ NSForegroundColorAttributeName: pColor}];
            _inputTextField.attributedPlaceholder = str;
        }
    }
    
    rect = self.frame;
    rect.size.height = _inputTextField.frame.size.height;
    self.frame  = rect;
    
    [self updateView];
    [self setKeyboardType];
    [self addLeftSpacer];
    [self addSubview:_inputTextField];
    
    if ([self.viewModel.state isEqualToString:@"invisible"]) {
        self.hidden = YES;
    }
}

-(void)updateView
{
    if (self.viewModel.val.length)
    {
        [MWFMLStringParser parseFMLString:self.viewModel.val
                                  forChat:self.viewModel.chat
                        completionHandler:^(NSString *parsedString) {
                            [self setText:parsedString];
                        }];
    }
}

-(void)setText:(NSString *)text
{
    self.inputedText =  text;
    _inputTextField.text = self.inputedText;
}

-(void)setKeyboardType
{
    self.viewModel.modelRegExp = @"NA";
    
    if ([self.viewModel.it isEqualToString:@"phone"]) {
        self.viewModel.modelRegExp = @"/^\+[0-9]{7,17}$/";
        [_inputTextField setKeyboardType:UIKeyboardTypePhonePad];
    }
    else if ([self.viewModel.it isEqualToString:@"text"]) {
        _inputTextField.autocorrectionType = UITextAutocorrectionTypeDefault;
        [_inputTextField setKeyboardType:UIKeyboardTypeDefault];
        _inputTextField.returnKeyType = UIReturnKeyDone;
    }
    else if ([self.viewModel.it isEqualToString:@"number"]) {
        self.viewModel.modelRegExp = @"/^[0-9]*$/";
        [_inputTextField setKeyboardType:UIKeyboardTypeNumberPad];
        _inputTextField.inputAccessoryView = [self createDoneButtonView];
    }
    else if ([self.viewModel.it isEqualToString:@"cardnumber"]) {
        
        [_inputTextField setKeyboardType:UIKeyboardTypeNumberPad];
        _inputTextField.inputAccessoryView = [self createDoneButtonView];
    }
    else if ([self.viewModel.it isEqualToString:@"datetime"]) {
        
        [_inputTextField setKeyboardType:UIKeyboardTypeNumberPad];
        _inputTextField.inputAccessoryView = [self createDoneButtonView];
    }
    else if ([self.viewModel.it isEqualToString:@"float"]) {
        
        self.viewModel.modelRegExp = @"/^[0-9.]*$/";
        [_inputTextField setKeyboardType:UIKeyboardTypeDecimalPad];
        _inputTextField.inputAccessoryView = [self createDoneButtonView];
    }
    else if ([self.viewModel.it isEqualToString:@"pass_text"]) {
        
        [_inputTextField setSecureTextEntry:YES];
    }
    else if ([self.viewModel.it isEqualToString:@"pass_num"]) {
        
        self.viewModel.modelRegExp = @"/^[0-9]*$/";
        [_inputTextField setKeyboardType:UIKeyboardTypeNumberPad];
        _inputTextField.inputAccessoryView = [self createDoneButtonView];
        [_inputTextField setSecureTextEntry:YES];
    }
    else if ([self.viewModel.it isEqualToString:@"mail"]) {
        
        self.viewModel.modelRegExp = @"/^[^\s@]+@[^\s@]+\.[^\s@]+$/";
        [_inputTextField setKeyboardType:UIKeyboardTypeEmailAddress];
        _inputTextField.inputAccessoryView = [self createDoneButtonView];
    }
    else if ([self.viewModel.it isEqualToString:@"calendar"]) {
        
    }
}

- (UIView *)createDoneButtonView
{
    UIToolbar * toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
    UIBarButtonItem * space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                            target:nil
                                                                            action:NULL];
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                 target:self
                                                                                 action:@selector(loseFocus)];
    doneButton.tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    toolbar.items = @[space, doneButton];
    return toolbar;
}

#pragma mark - UITextField

- (void)addLeftSpacer {
    
    if (![self.viewModel.talign isEqualToString:@"center"]) {
        
        if ([self.viewModel.talign isEqualToString:@"right"]) {
            [_inputTextField setRightViewMode:UITextFieldViewModeAlways];
        }
        else {
            UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10.0, 10.0)];
            [_inputTextField setLeftViewMode:UITextFieldViewModeAlways];
            [_inputTextField setLeftView:spacerView];
        }
    }
}

- (void)loseFocus
{
    [_inputTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self loseFocus];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
//    [PBConsoleConstants makeTextFieldUnselected:_inputTextField];
    if (!_inputTextField.text.length) {
        
        if (!self.viewModel.hint.length) {
            self.inputedText =  [self.viewModel.val description];
            _inputTextField.text = self.inputedText;
        }
        else {
//            [_inputTextField setFont:[PBConsoleConstants placehokredTextFieldFont]];
            [_inputTextField setPlaceholder:self.viewModel.hint];
        }
    }
    [self loseFocus];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
//    [PBConsoleConstants makeTextFieldSelected:_inputTextField];
    [textField setFont:[PBConsoleConstants inputTextFieldFontStyle:self.viewModel.fontStyle
                                                           andSize:self.viewModel.fontSize+2]];
}

- (BOOL)            textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
            replacementString:(NSString *)string
{
    if (textField.keyboardType == UIKeyboardTypeDecimalPad)
        string = [string stringByReplacingOccurrencesOfString:@"," withString:@"."];

    if ([self.viewModel.it isEqualToString:@"phone"])
    {
        BOOL shouldReplaceString = [[ParamsFacade sharedInstance] checkPhoneField:textField
                                                                            range:range
                                                                replacementString:string];

        if (shouldReplaceString && textField.keyboardType == UIKeyboardTypeDecimalPad)
        {
            textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
            return NO;
        }

        return shouldReplaceString;
    }

    if (textField.keyboardType == UIKeyboardTypeDecimalPad)
    {
        textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        return NO;
    }

    
    return YES;
}

- (IBAction)textFieldDidChanged:(UITextField *)sender {
    
    self.viewModel.val = _inputTextField.text;
}

@end
