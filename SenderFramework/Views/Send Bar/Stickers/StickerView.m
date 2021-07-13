//
//  StickerView.m
//  SENDER
//
//  Created by Roman Serga on 23/1/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "StickerView.h"

@implementation StickerView
{
    NSDictionary * allStickers;
    NSArray * stickerPack;
    NSString * packName;
    
    NSMutableArray * buttons;
        
    IBOutlet UIScrollView * chooseView;
}


-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        buttons = [NSMutableArray array];
        NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
        self = [[NSBundle.senderFrameworkResourcesBundle loadNibNamed:@"StickerView" owner:self options:nil] objectAtIndex:0];
        
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, SCREEN_WIDTH, self.frame.size.height);
        chooseView.frame = CGRectMake(chooseView.frame.origin.x, chooseView.frame.origin.y, self.frame.size.width, self.frame.size.height);
        allStickers = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.senderFrameworkResourcesBundle pathForResource:@"Stickers" ofType:@"plist"]];
        
        CGFloat packBtnWidth = 100;
        CGFloat packBtnHeight = 109;
        CGFloat offset = 6.3f;
        
        if (IS_IPHONE_6) offset = 21.0f;
        if (IS_IPHONE_6P) offset = 30.0f;
        if (IS_IPAD) offset = (SCREEN_WIDTH - [allStickers[@"Stickers"]count] * packBtnWidth) / ([allStickers[@"Stickers"]count] + 1);

        int delta = 0;
        for (NSDictionary * pack in allStickers[@"Stickers"])
        {
            NSString * packTitle = pack[@"Title"];
            NSUInteger indexOfPack = [allStickers[@"Stickers"] indexOfObject:pack] + delta;
            
            UIButton * stickerPackButton = [[UIButton alloc]initWithFrame:CGRectMake((offset - 10.0f) + packBtnWidth * indexOfPack + offset * indexOfPack, (chooseView.frame.size.height - packBtnHeight) / 2, packBtnWidth, packBtnHeight)];
            stickerPackButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            [stickerPackButton setTitle:packTitle forState:UIControlStateNormal];
            [stickerPackButton setImage:[UIImage imageFromSenderFrameworkNamed:pack[@"Preview"]] forState:UIControlStateNormal];
            [stickerPackButton addTarget:self action:@selector(openStickerPack:) forControlEvents:UIControlEventTouchUpInside];
            
            chooseView.contentSize = CGSizeMake(stickerPackButton.frame.origin.x + stickerPackButton.frame.size.width, chooseView.frame.size.height);
            [chooseView addSubview:stickerPackButton];
        }
        
        [self addSubview:chooseView];
    }
    return self;
}

-(void)goBack
{
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.frame.size.height);
    [self addSubview:chooseView];
    for (StickerButton * button in buttons) {
        [button removeFromSuperview];
    }
    buttons = [NSMutableArray array];
}

-(IBAction)openStickerPack:(id)sender
{
    int stickersPerPage = 8;
    if (IS_IPHONE_6) stickersPerPage = 10;
    else if (IS_IPHONE_6P) stickersPerPage = 10;
    else if (IS_IPAD) stickersPerPage = 18;

    [chooseView removeFromSuperview];
    packName = [[(UIButton *)sender titleLabel]text];
    for (NSDictionary * pack in allStickers[@"Stickers"]) {
        if ([pack[@"Title"] isEqualToString:packName])
        {
            stickerPack = pack[@"Stickers"];
            break;
        }
    }
    unsigned long numOfPages = ([stickerPack count] % stickersPerPage == 0 ? [stickerPack count] / stickersPerPage : ([stickerPack count] / stickersPerPage) + 1);    
    [self setStickersFromArray:stickerPack];
    self.frame = CGRectMake(0, 0,SCREEN_WIDTH  * numOfPages, self.frame.size.height);

    [self.delegate stickerViewDidOpenedStickerPack];
}

-(void)setStickersFromArray:(NSArray*)array
{
    buttons = [NSMutableArray array];
    CGFloat btnWidth = 70.0f;
    
    int stickersPerPage = 8;

    if (IS_IPHONE_6) stickersPerPage = 10;
    else if (IS_IPHONE_6P) stickersPerPage = 10;
    else if (IS_IPAD) stickersPerPage = 18;

    CGFloat offset = SCREEN_WIDTH - (([array count] >= stickersPerPage ? stickersPerPage : [array count])  / 2) * btnWidth;


    for (NSString * name in array)
    {
        StickerButton * button = [[StickerButton alloc]init];
        button.pictureName = name;
        NSUInteger pictureIndex = [array indexOfObject:name];
        CGFloat x = offset / 2 + btnWidth * (pictureIndex / 2) + offset * (pictureIndex / stickersPerPage);
        CGFloat y = 20.0f + (btnWidth + 10.0f) * (pictureIndex % 2);
        button.frame = CGRectMake(x, y, btnWidth, btnWidth);
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [button setImage:[UIImage imageFromSenderFrameworkNamed:name] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(sendSticker:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:button];
        [buttons addObject:button];
    }
}

-(void)sendSticker:(StickerButton*)sender
{
    [self.delegate stickerViewDidSelectedSticker:sender.pictureName];
}

@end
