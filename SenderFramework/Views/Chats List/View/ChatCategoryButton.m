//
// Created by Roman Serga on 30/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatCategoryButton.h"

@implementation ChatCategoryButton
{
    CGFloat smallBottomLineHeight;
    CGFloat bigBottomLineHeight;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self addBottomLine];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self addBottomLine];
    }
    return self;
}

- (void)addBottomLine
{
    if (!self.bottomLine)
    {
        smallBottomLineHeight = 1.0f;
        bigBottomLineHeight = 2.0f;

        CGRect bottomLineFrame = CGRectMake(0.0f, self.frame.size.height - smallBottomLineHeight, self.frame.size.width, smallBottomLineHeight);
        self.bottomLine = [[UIView alloc] initWithFrame:bottomLineFrame];
        self.bottomLine.backgroundColor = [UIColor lightGrayColor];
        self.bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.bottomLine];

        NSLayoutAttribute attributes[] = {NSLayoutAttributeLeft, NSLayoutAttributeRight, NSLayoutAttributeBottom};
        for (int i = 0; i < 3; i++)
        {
            NSLayoutAttribute attribute = attributes[i];
            NSLayoutConstraint  * constraint = [NSLayoutConstraint constraintWithItem:self
                                                                            attribute:attribute
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.bottomLine
                                                                            attribute:attribute
                                                                           multiplier:1.0f
                                                                             constant:0.0f];
            [self addConstraint:constraint];
        }

        self.bottomLineHeight = [NSLayoutConstraint constraintWithItem:self.bottomLine
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1.0f
                                                              constant:smallBottomLineHeight];
        [self.bottomLine addConstraint:self.bottomLineHeight];
    }
}

- (void)setBigBottomLine:(BOOL)bigBottomLine
{
    _bigBottomLine = bigBottomLine;
    self.bottomLineHeight.constant = _bigBottomLine ? bigBottomLineHeight : smallBottomLineHeight;
    [self layoutIfNeeded];
}

@end