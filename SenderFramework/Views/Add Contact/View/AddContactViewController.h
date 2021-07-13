//
//  AddContactViewController.h
//  SENDER
//
//  Created by Roman Serga on 29/7/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddContactViewProtocol;
@protocol AddContactPresenterProtocol;
@protocol ModalInNavigationWireframeEventsHandler;

@interface AddContactViewController : UITableViewController <UITextFieldDelegate, AddContactViewProtocol,
        ModalInNavigationWireframeEventsHandler>

@property (nonatomic, strong) id<AddContactPresenterProtocol> presenter;

@end
