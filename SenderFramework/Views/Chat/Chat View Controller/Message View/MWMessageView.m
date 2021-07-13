//
// Created by Roman Serga on 28/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "MWMessageView.h"

@implementation MWMessageViewAction

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        self->_name = name;
    }
    return self;
}

+ (MWMessageViewAction *)edit
{
    return [[MWMessageViewAction alloc] initWithName:@"edit"];
}

+ (MWMessageViewAction *)delete
{
    return [[MWMessageViewAction alloc] initWithName:@"delete"];
}

@end

@implementation MWMessageViewUpdate

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self)
    {
        self->_name = name;
    }
    return self;
}

@end


@implementation MWMessageView
{

}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setUpView];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setUpView];
    }

    return self;
}

- (void)setUpView
{

}

- (void)handleUpdate:(MWMessageViewUpdate *)messageViewUpdate
{

}

@end
