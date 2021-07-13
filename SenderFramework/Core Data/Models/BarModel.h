//
//  BarModel.h
//  SENDER
//
//  Created by Eugene Gilko on 8/31/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BarItem;
@class Dialog;

@interface BarModel : NSManagedObject

@property (nonatomic, retain) NSData * initializeData;
@property (nonatomic, retain) NSString * mainTextColor;
@property (nonatomic, retain) NSSet<BarItem *>* barItems;

@property (nonatomic, retain) Dialog * dialog;
@property (nonatomic, retain) Dialog * operatorDialog;

@end

@interface BarModel (CoreDataGeneratedAccessors)

- (void)addBarItemsObject:(BarItem *)value;
- (void)removeBarItemsObject:(BarItem *)value;
- (void)addBarItems:(NSSet *)values;
- (void)removeBarItems:(NSSet *)values;

@end
