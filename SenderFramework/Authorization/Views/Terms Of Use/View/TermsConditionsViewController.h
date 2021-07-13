//
//  TermsConditionsViewController.h
//  SENDER
//
//  Created by Roman Serga on 23/3/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TermsConditionsViewProtocol;
@protocol TermsConditionsPresenterProtocol;

@interface TermsConditionsViewController : UIViewController <TermsConditionsViewProtocol>

@property (nonatomic, strong) id<TermsConditionsPresenterProtocol> presenter;

@end
