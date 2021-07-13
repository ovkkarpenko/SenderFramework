//
//  ProgressView.h
//  SENDER
//
//  Created by Roman Serga on 18/3/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressView : UIView

- (instancetype)initWithFrame:(CGRect)frame text:(NSString *)text;
- (instancetype)initWithText:(NSString *)text;

@property (nonatomic, strong) NSString * text;

@end
