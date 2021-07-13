//
//  PBRadioButtonView.m
//  Sender
//
//  Created by Eugene Gilko on 9/18/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBRadioButtonView.h"
#import "UIImage+animatedGIF.h"
#import "PBConsoleConstants.h"
#import "ServerFacade.h"

@implementation PBRadioButtonView
{
    UIImageView * imgView;
}

- (id)initWithModel:(PBCheckBoxModel *)model andRect:(CGRect)rect
{
    if (model.imgLinkl.length) {
        if ((self = [super initWithFrame:CGRectMake(0, rect.origin.y, rect.size.width, 125.0)])) {
            [self configWithImg:rect setupWithModel:model];
        }
    }
    else {
        if ((self = [super initWithFrame:CGRectMake(0, rect.origin.y, rect.size.width, 35.0)])) {
            [self config:rect setupWithModel:model];
        }
    }
    
    return self;
}


- (void)config:(CGRect)mainRect setupWithModel:(PBCheckBoxModel *)model
{
    self.boxModel = model;
    
    boxImage = [[UIImageView alloc] initWithImage:[self imageForBox]];
    
    boxImage.frame = CGRectMake(0, 5, boxImage.frame.size.width, boxImage.frame.size.height);
    
    [self addSubview:boxImage];
    
    CGSize size = CalculateSenderHeaderSize (model.title, [PBConsoleConstants inputTextFieldFont], self.frame.size.width - boxImage.frame.size.width - 30.0);
    
    UITextView * headerText = [[UITextView alloc] initWithFrame:CGRectMake(boxImage.frame.size.width + 10.0, 0, size.width + 10, size.height)];
    headerText.backgroundColor = [UIColor clearColor];
    
    [headerText setFont:[PBConsoleConstants inputTextFieldFont]];
    
    if (![model.title isKindOfClass:[NSNull class]]) {
        headerText.text = model.title;
    }
    
    [headerText setEditable:NO];
    [headerText setScrollEnabled:NO];
    headerText.userInteractionEnabled = NO;
    headerText.dataDetectorTypes = UIDataDetectorTypeAll;
    [headerText sizeToFit];
    [self addSubview:headerText];
    CGRect rect = self.frame;
    rect.size.height = headerText.frame.size.height;
    self.frame = rect;
    rect.origin.y = 0;
    UIButton * button = [[UIButton alloc] initWithFrame:rect];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(pushTheCell) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
}

- (void)configWithImg:(CGRect)mainRect setupWithModel:(PBCheckBoxModel *)model
{
    self.boxModel = model;
    
    [[ServerFacade sharedInstance] downloadImageWithBlock:[^(UIImage * image) {
        self.boxModel.cellImage = image;
    } copy] forUrl:self.boxModel.imgLinkl];
    
    boxImage.frame = CGRectMake(0, 5, boxImage.frame.size.width, boxImage.frame.size.height);
    
    [self addSubview:boxImage];
    
    CGSize size = CalculateSenderHeaderSize(model.title, [PBConsoleConstants inputTextFieldFont], self.frame.size.width - boxImage.frame.size.width - 30.0);
    
    UITextView * headerText = [[UITextView alloc] initWithFrame:CGRectMake(boxImage.frame.size.width + 10.0f, 0.0f, self.frame.size.width, size.height)];
    headerText.backgroundColor = [UIColor clearColor];
    
    [headerText setFont:[PBConsoleConstants inputTextFieldFont]];
    
    if (![model.title isKindOfClass:[NSNull class]]) {
        headerText.text = model.title;
    }
    
    [headerText setEditable:NO];
    [headerText setScrollEnabled:NO];
    headerText.userInteractionEnabled = NO;
    headerText.dataDetectorTypes = UIDataDetectorTypeAll;
    [headerText sizeToFit];
    [self addSubview:headerText];
    CGRect rect = self.frame;
    rect.size.height = headerText.frame.size.height;
    self.frame = rect;
    rect.origin.y = 0;
    UIButton * button = [[UIButton alloc] initWithFrame:rect];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self action:@selector(pushTheCell) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];

}

- (void)changeViewMode:(bool)mode
{
    self.boxModel.selected = mode;
    boxImage.image = [self imageForBox];
}

- (IBAction)pushTheCell
{
    [self.delegate pushOnRadio:self didFinishEnteringItem:self.boxModel];
}

- (UIImage *)imageForBox
{
    if (self.boxModel.selected) {
        return [UIImage imageFromSenderFrameworkNamed:@"select_radiobutton"];
    }
    return [UIImage imageFromSenderFrameworkNamed:@"unselect_radiobutton"];
}

- (void)downloadImageWithBlock:(void(^)(UIImage * image))block forUrl:(NSString *)urlString
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSError * error;
            NSData * imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]
                                                       options:NSDataReadingUncached
                                                         error:&error];
            
            if (!imageData) {
                return ;
            }
            
            UIImage * newImage = [UIImage animatedImageWithAnimatedGIFData:imageData];
            block(newImage);
            
            [self performSelectorOnMainThread:@selector(receivedImage)
                                   withObject:nil waitUntilDone:YES];
            
        }
    });
}

- (void)receivedImage
{
    imgView.image = self.boxModel.cellImage;
}

@end
