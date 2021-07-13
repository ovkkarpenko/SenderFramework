//
//  PBLoadFileView.m
//  SENDER
//
//  Created by Eugene Gilko on 4/11/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "PBLoadFileView.h"
#import "ConsoleCaclulator.h"
#import "ServerFacade.h"
#import "MainContainerModel.h"

@implementation PBLoadFileView

@dynamic viewModel;

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];
    
    self.viewModel = submodel;
    if (!self.viewModel.title) {
        self.viewModel.title = @"empy";
    }
    float startX = 0;
    if (mainRect.origin.x > 0)
        startX = mainRect.origin.x;
    
    self.frame = CGRectMake(startX, mainRect.origin.y, mainRect.size.width, 50.0);
    self.backgroundColor = [UIColor clearColor];
    
    CGRect bttRect = CGRectMake(0, 0, 80, 40);
    _loadLinkButton = [[UIButton alloc] initWithFrame:bttRect];

    [_loadLinkButton setTitleColor:[PBConsoleConstants colorDeepBlue] forState:UIControlStateNormal];
    [_loadLinkButton setTitle:@"Select file:" forState:UIControlStateNormal];
    UIFont * buttonFont = [PBConsoleConstants inputTextFieldFontStyle:@"-Bold" andSize:15];
    [_loadLinkButton.titleLabel setFont:buttonFont];
    [_loadLinkButton addTarget:self action:@selector(linkButtonPushedAction:)
              forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:_loadLinkButton];
    
    bttRect = CGRectMake(85, 0, mainRect.size.width - startX - 85, 40);
    _fileName = [[UILabel alloc] initWithFrame:bttRect];
    [_fileName setText:self.viewModel.title];
    [_fileName setTextColor:[UIColor grayColor]];
    [_fileName setFont:[PBConsoleConstants inputTextFieldFontStyle:@"-Italic" andSize:14]];
    [self addSubview:_fileName];
}

- (IBAction)linkButtonPushedAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(loadFileForFileView:)])
        [self.delegate loadFileForFileView:self];
}

- (void)setImageURL:(NSURL *)imageURL imageData:(NSData *)imageData
{
    self.viewModel.title = @"Loaded!";
    [_fileName setText:self.viewModel.title];
    self.viewModel.val = imageURL.absoluteString;
}

@end
