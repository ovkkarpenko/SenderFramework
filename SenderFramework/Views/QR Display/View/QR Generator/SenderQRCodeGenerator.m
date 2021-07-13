//
//  SenderQRCodeGenerator.m
//  SENDER
//
//  Created by Roman Serga on 11/01/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "SenderQRCodeGenerator.h"

@implementation SenderQRCodeGenerator

+ (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)size withColor:(UIColor *)color
{
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    [filter setDefaults];
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    
    CIImage *outputImage = [filter outputImage];
    
    CIFilter * colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
    [colorFilter setValue:outputImage forKey:@"inputImage"];
    [colorFilter setValue:[[CIColor alloc]initWithColor:color] forKey:@"inputColor0"];
    [colorFilter setValue:[[CIColor alloc]initWithColor:[UIColor whiteColor]] forKey:@"inputColor1"];
    
    outputImage = [colorFilter outputImage];
    
    CIContext * context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:outputImage
                                       fromRect:[outputImage extent]];
    
    UIImage *image = [UIImage imageWithCGImage:cgImage
                                         scale:1.0f
                                   orientation:UIImageOrientationUp];
    
    UIImage * resized = [self resizeImage:image withQuality:kCGInterpolationNone rate:size / image.size.height];
    
    CGImageRelease(cgImage);
    
    return resized;
}

+ (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)size
{
    return [self qrImageForString:string imageSize:size withColor:[UIColor blackColor]];
}

+ (UIImage *)resizeImage:(UIImage *)image withQuality:(CGInterpolationQuality)quality rate:(CGFloat)rate
{
    UIImage *resized = nil;
    CGFloat width = image.size.width * rate;
    CGFloat height = image.size.height * rate;
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, quality);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resized;
}

@end
