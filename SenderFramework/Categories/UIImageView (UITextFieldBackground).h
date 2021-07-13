//
//  UITextField+Background.h
//  Privat24-ios
//
//  Created by Dima Yarmolchuk on 20.06.13.
//  Copyright (c) 2013 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIImageView (UITextFieldBackground)

- (void)setStretchablesenderFrameworkImageNamed:(NSString *)name;
- (void)setStretchableBgImage:(NSString *)name;
- (void)setStretchableBalon:(NSString *)name;
- (void)setUserPicture:(NSString *)name;
- (void)setFadeingDownBg:(NSString *)name;


- (void)setStretchableOwnerBalon:(NSString *)name;
- (void)setStretchableGuestBalon:(NSString *)name;
@end
