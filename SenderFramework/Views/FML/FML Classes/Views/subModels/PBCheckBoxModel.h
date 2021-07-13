//
//  PBCheckBoxModel.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/25/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PBCheckBoxModel : NSObject

- (id)initWithData:(NSDictionary *)data;

@property (nonatomic) bool selected;
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * value;
@property (nonatomic, strong) NSString * imgLinkl;
@property (nonatomic, strong) UIImage * cellImage;
@property (nonatomic, strong) NSDictionary * action;
@property (nonatomic, strong) NSArray * actions;
@property (nonatomic) bool isRadioButton;
@property (nonatomic) int cellIndificator;

@end
