//
//  PBImageView.m
//  ZiZZ
//
//  Created by Eugene Gilko on 7/25/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import "PBImageView.h"
#import "UIImage+animatedGIF.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>
#import "File.h"
#import "ParamsFacade.h"
#import "CoreDataFacade.h"
#import "ServerFacade.h"
#import "ConsoleCaclulator.h"
#import "Owner.h"
#import "MainContainerModel.h"
#import "NSURL+MW_PercentEscapes.h"
#import <SenderFramework/SenderFramework-Swift.h>

@interface PBImageView()
{
    UIImageView * imgView;
}

@end

@implementation PBImageView

@dynamic viewModel;

- (void)settingViewWithRect:(CGRect)mainRect andModel:(MainContainerModel *)submodel
{
    [super settingViewWithRect:mainRect andModel:submodel];
    self.viewModel = submodel;
    float widthImg = mainRect.size.width;

    if (self.viewModel.w) {
        widthImg = (float)[self.viewModel.w floatValue];
    }

    float heightImg = (mainRect.size.height > 0) ? mainRect.size.height : 100;

    if (self.viewModel.h) {
        heightImg = (float)[self.viewModel.h floatValue];
    }

    self.frame = CGRectMake(0, 0, widthImg, heightImg);
    self.backgroundColor = [UIColor clearColor];

    [self imageWithRect:self.frame];
}

- (void)setImageData:(Contact *)contact
{
    NSURL * encodedImageURL = [NSURL mw_URLByAddingPercentEscapesToString:contact.imageURL];
    [imgView sd_setImageWithURL:encodedImageURL];
}

- (void)imageWithRect:(CGRect)mainRect
{
    imgView = [[UIImageView alloc] initWithFrame:mainRect];

    if ([self.viewModel.src length] >= 3 && [[self.viewModel.src substringToIndex:3] isEqualToString:@"{{!"])
    {
        NSString * tmp = [self.viewModel.src substringFromIndex:8];
        tmp = [tmp substringToIndex:tmp.length - 2];
        NSArray * urls = [tmp componentsSeparatedByString:@"."];

        if ([urls[1] isEqualToString:@"photo"])
        {
            if ([urls[0] isEqualToString:[CoreDataFacade sharedInstance].ownerUDIDString] ||
                    [urls[0] isEqualToString:@"me"])
            {
                Owner * owner = [[CoreDataFacade sharedInstance] getOwner];
                UIImage * placeHolder = [MWDefaultImageGenerator generateDefaultImageWithEmoji:owner.defaultImageEmoji
                                                                                          size:imgView.frame.size
                                                                                       rounded:NO
                                                                           backgroundImageName:@"icAccount"];
                [imgView sd_cancelCurrentImageLoad];
                [imgView sd_setImageWithURL:owner.imageURL placeholderImage:placeHolder];
            }
            else if ([urls[0] isEqualToString:@"!user"])
            {
                NSString * userID = userIDFromChatID(self.viewModel.chat.chatID);
                Contact * contact = [[CoreDataFacade sharedInstance] selectContactById:userID];
                [self setImageData:contact];
            }
            else
            {
                Contact * contact = [[CoreDataFacade sharedInstance] selectContactById:urls[0]];
                [self setImageData:contact];
            }
        }
    }
    else
    {
        NSString * encodedString = [self.viewModel.src stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [imgView sd_setImageWithURL:[NSURL URLWithString:encodedString]];
    }

    if (self.viewModel.h && self.viewModel.w) {
        [imgView setContentMode:UIViewContentModeScaleToFill];
    }
    else {
        [imgView setContentMode:UIViewContentModeScaleAspectFit];
    }
    [self addSubview:imgView];
    [PBConsoleConstants settingViewBorder:imgView andModel:self.viewModel];

    UIButton * actButton = [[UIButton alloc] initWithFrame:self.frame];
    [actButton addTarget:self action:@selector(doActionBtt:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:actButton];
}

- (IBAction)doActionBtt:(id)sender
{
    [super doAction:self.viewModel.action];
}

- (void)setImage:(NSData *)imageData
{
    imgView.image = [UIImage imageWithData:imageData];
}

@end
