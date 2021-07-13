//
// Created by Roman Serga on 30/1/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatCategoryButton: UIButton

@property (nonatomic, strong) UIView * bottomLine;
@property (nonatomic) BOOL bigBottomLine;

@property (nonatomic, strong) NSLayoutConstraint * bottomLineHeight;

@end