//
//  ComplainPopUp.h
//  SENDER
//
//  Created by Eugene on 4/15/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ComplainPopUp;

@protocol ComplainPopUpDelegate <NSObject>

- (void)complainPopUpDidFinishEnteringText:(NSString *)reportText;

@end


@interface ComplainPopUp : UIView

@property (nonatomic, weak) id<ComplainPopUpDelegate> delegate;

@end
