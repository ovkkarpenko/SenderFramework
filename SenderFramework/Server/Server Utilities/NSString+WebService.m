//
//  Created by Eugene on 3/1/13.
//  NSString+WebService.m


#import "NSString+WebService.h"

@implementation NSString (WebService)
- (id)JSON
{
    NSData * data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingMutableLeaves|NSJSONReadingMutableContainers
                                             error:nil];
}

- (NSString *)URLEncode
{
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                     NULL,
                                                                     (__bridge CFStringRef)self,
                                                                     NULL,
                                                                     (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                     kCFStringEncodingUTF8));
}

@end
