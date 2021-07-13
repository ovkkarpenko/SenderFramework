//
// Created by Roman Serga on 12/20/16.
// Copyright (c) 2016 Middleware Inc. All rights reserved.
//

#import "UIView+FindSearchTextField.h"

@implementation UIView (FindSearchTextField)

- (UITextField *)searchTextField
{
    if ([self isKindOfClass:NSClassFromString(@"UISearchBarTextField")])
        return (UITextField *)self;

    UITextField * result;

    for (UIView * subview in [self subviews])
    {
        UITextField * searchTextField = [subview searchTextField];
        if (searchTextField)
        {
            result = searchTextField;
            break;
        }
    }
    return result;
}

@end