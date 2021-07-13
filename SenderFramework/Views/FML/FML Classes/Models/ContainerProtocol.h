//
//  ContainerProtocol.h
//  SENDER
//
//  Created by Eugene on 10/16/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ContainerProtocol <NSObject>

@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * bg;
@property (nonatomic, strong) NSString * val;
@property (nonatomic, strong) NSString * hint;
@property (nonatomic, strong) NSNumber * w;
@property (nonatomic, strong) NSNumber * h;
@property (nonatomic, strong) NSString * weight;
@property (nonatomic, strong) NSNumber * totalWeight;
@property (nonatomic, strong) NSNumber * topTotalWeight;
@property (nonatomic, strong) NSString * src;
@property (nonatomic, strong) NSDictionary * action;
@property (nonatomic, strong) NSDictionary * actions;
@property (nonatomic, strong) NSArray * pd;
@property (nonatomic, strong) NSArray * mg;
@property (nonatomic, strong) NSArray * items;
@property (nonatomic, strong) NSString * state;
@property (nonatomic, strong) NSArray * vars;
@property (nonatomic, strong) NSString * vars_type;
@property (nonatomic, strong) NSString * it;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * b_size;
@property (nonatomic, strong) NSString * b_color;
@property (nonatomic, strong) NSString * b_radius;
@property (nonatomic, strong) NSString * talign;
@property (nonatomic, strong) NSString * valign;
@property (nonatomic, strong) NSString * halign;
@property (nonatomic, strong) NSString * regexp;
@property (nonatomic, strong) NSString * regexpText;
@property (nonatomic, assign) BOOL required;
@property (nonatomic) int bottomPadding;
@property (nonatomic, strong) NSString * modelRegExp;

//наследуемые параметры для текста!!!!!
@property (nonatomic, strong) NSString * size;
@property (nonatomic, strong) NSString * color;
@property (nonatomic, strong) NSArray * tstyle;

@end
