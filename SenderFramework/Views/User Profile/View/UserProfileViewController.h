//
//  UserProfileViewController.h
//  SENDER
//
//  Created by Eugene Gilko on 11/2/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

@protocol UserProfileViewProtocol;
@protocol UserProfilePresenterProtocol;
@protocol ModalInNavigationWireframeEventsHandler;
@protocol AddToContainerWireframeEventsHandler;

@interface UserProfileViewController : UIViewController  <UICollectionViewDataSource,
                                                          UICollectionViewDelegateFlowLayout,
                                                          UserProfileViewProtocol,
                                                          AddToContainerWireframeEventsHandler,
                                                          ModalInNavigationWireframeEventsHandler>

@property (nonatomic, nullable) id<UserProfilePresenterProtocol> presenter;

- (void)updateInfo;

@end