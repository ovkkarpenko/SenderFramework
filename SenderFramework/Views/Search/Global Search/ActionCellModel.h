//
//  ActionCellModel.h
//  SENDER
//
//  Created by Eugene Gilko on 11/9/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActionCellModel : NSObject

@property (nonatomic, strong) NSString * cellImageURL;
@property (nonatomic, strong) NSString * cellName;
@property (nonatomic, strong) NSString * cellClass;
@property (nonatomic, strong) NSString * cellOper;
@property (nonatomic, strong) NSString * cellUserID;
@property (nonatomic, strong) NSDictionary * cellActionData;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (void)setActionModel:(NSDictionary *)action;

@end
