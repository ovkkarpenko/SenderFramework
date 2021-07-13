//
//  ValueSelectTableViewController.h
//  SENDER
//
//  Created by Roman Serga on 21/4/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ValueSelectTableViewController;

@protocol ValueSelectTableViewControllerDelegate <NSObject>

-(void)valueSelectTableViewController:(ValueSelectTableViewController *)controller
                   didFinishWithValueAtIndex:(NSInteger)index;

@end

@interface ValueSelectTableViewController : UITableViewController

@property (nonatomic, weak) id<ValueSelectTableViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray<NSString *> * values;
@property (nonatomic) NSUInteger indexOfSelectedValue;

- (void)update;

@end
