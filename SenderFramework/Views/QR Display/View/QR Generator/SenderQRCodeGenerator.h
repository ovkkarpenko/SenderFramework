//
//  SenderQRCodeGenerator.h
//  SENDER
//
//  Created by Roman Serga on 11/01/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SenderQRCodeGenerator : NSObject

+ (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)size;
+ (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)size withColor:(UIColor *)color;

@end
