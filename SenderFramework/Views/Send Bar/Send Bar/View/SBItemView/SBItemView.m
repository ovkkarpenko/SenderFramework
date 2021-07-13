//
//  SBItemView.m
//  SENDER
//
//  Created by Roman Serga on 4/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "SBItemView.h"
#import "ParamsFacade.h"
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import <SDWebImage/UIButton+WebCache.h>
#import "Settings.h"
#import "Owner.h"
#import "SBItemView_protected.h"

#define titleLabelHeightMultiplyer (42.0f / 150.0f)

@interface SBItemView ()

@end

@implementation SBItemView

@synthesize actionButton = _actionButton;
@synthesize titleLabel = _titleLabel;
@synthesize titleLabelHeight = _titleLabelHeight;

-(instancetype)initWithFrame:(CGRect)frame andItemModel:(BarItem *)itemModel
{
    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
    self = [NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"SBItemView" owner:nil options:nil][0];
    if (self)
    {
        self.frame = frame;
        self.itemModel = itemModel;
        self.actionButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        if ([self.itemModel.icon length])
            [self.actionButton sd_setImageWithURL:[self URLForIconWithLink:self.itemModel.icon] forState:UIControlStateNormal];
        if ([self.itemModel.icon2 length])
            [self.actionButton sd_setImageWithURL:[self URLForIconWithLink:self.itemModel.icon2] forState:UIControlStateSelected];
        if ([itemModel.name length])
            [self setLocalizedTitleFromData:itemModel.name];
        else
            self.hidesTitle = YES;
        
        if (self.titleTextColor)
            [self.titleLabel setTextColor:self.titleTextColor];
        
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
    _titleTextColor = titleTextColor;
//    [self.titleLabel setTextColor:_titleTextColor];
}

- (NSURL *)URLForIconWithLink:(NSString *)link withCustomScale:(NSString *)imageScale
{
    NSArray * components = [link componentsSeparatedByString:@"."];
    
    NSString * resultString = @"";
    
    for (NSString * component in components)
    {
        if ([components indexOfObject:component] == ([components count] - 2))
            resultString = [resultString stringByAppendingString:[component stringByAppendingString:imageScale]];
        else
            resultString = [resultString stringByAppendingString:component];
        
        if ([components indexOfObject:component] != ([components count] - 1))
            resultString = [resultString stringByAppendingString:@"."];
    }
    
    return [NSURL URLWithString:resultString];
}

-(NSURL *)URLForIconWithLink:(NSString *)link
{
    NSString * imageScale = [[UIScreen mainScreen] scale] > 1.0f ? @"@2x" : @"";
    return [self URLForIconWithLink:link withCustomScale:imageScale];
}

-(instancetype)initWithItemModel:(BarItem *)itemModel
{
    return [self initWithFrame:CGRectZero andItemModel:itemModel];
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setHidesTitle: self.hidesTitle];
    [self layoutIfNeeded];
}

-(void)setDelegate:(id<SBItemViewDelegate>)delegate
{
    _delegate = delegate;
}

-(void)setSelected:(BOOL)selected
{
    _selected = selected;
    [self.actionButton setSelected:selected];
}

-(void)setHidesTitle:(BOOL)hidesTitle
{
    _hidesTitle = hidesTitle;
    self.titleLabelHeight.constant = hidesTitle ? 0.0f : self.frame.size.height * titleLabelHeightMultiplyer;
    [self layoutIfNeeded];
}

-(void)setLocalizedTitleFromData:(NSData *)data
{
    NSDictionary * titleDict = [[ParamsFacade sharedInstance]dictionaryFromNSData:data];
    NSString * settingsLanguage = DBSettings.language;
    NSString * titleString;
    if (settingsLanguage)
    {
        titleString = titleDict[settingsLanguage];
        if (!titleString)
        {
            NSString * languageWithoutCountry = [[settingsLanguage componentsSeparatedByString:@"-"] firstObject];
            if (languageWithoutCountry) titleString = titleDict[languageWithoutCountry];
        }
    }
    self.titleLabel.text = titleString ?: titleDict[@"en"];
}

-(IBAction)mainButtonPressed:(id)sender
{
    [self.delegate itemView:self didChooseActionsWithData:[(BarItem *)self.itemModel actionsParsed]];
}

@end
