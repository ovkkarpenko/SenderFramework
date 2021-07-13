//
// Created by Roman Serga on 1/5/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "NSString+EmojiHelpers.h"
#import <CoreText/CoreText.h>

@implementation NSString (EmojiHelpers)

-(BOOL)isSingleEmoji
{
    return [self containsEmoji] && [self glyphCount] == 1;
}

- (BOOL)containsEmoji
{
    __block BOOL result = NO;
    [self enumerateSubstringsInRange:NSMakeRange(0, [self length])
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                              const unichar unicodeChar = [substring characterAtIndex:0];

                              if (0xd800 <= unicodeChar && unicodeChar <= 0xdbff) {
                                  if (substring.length > 1) {
                                      const unichar ls = [substring characterAtIndex:1];
                                      const int uc = ((unicodeChar - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                                      if (0x1d000 <= uc && uc <= 0x1f77f) {
                                          result = YES;
                                      }
                                  }
                              } else if (substring.length > 1) {
                                  const unichar ls = [substring characterAtIndex:1];
                                  if (ls == 0x20e3) {
                                      result = YES;
                                  }
                                  else if ((0x2702 <= unicodeChar && unicodeChar <= 0x27B0) || unicodeChar == 0x263a) {
                                      result = YES;
                                  }

                              } else {
                                  // non surrogate
                                  if (0x2100 <= unicodeChar && unicodeChar <= 0x27ff) {
                                      result = YES;
                                  } else if (0x2B05 <= unicodeChar && unicodeChar <= 0x2b07) {
                                      result = YES;
                                  } else if (0x2B05 <= unicodeChar && unicodeChar <= 0x2b07) {
                                      result = YES;
                                  } else if (0x2934 <= unicodeChar && unicodeChar <= 0x2935) {
                                      result = YES;
                                  } else if (0x3297 <= unicodeChar && unicodeChar <= 0x3299) {
                                      result = YES;
                                  } else if (unicodeChar == 0xa9 || unicodeChar == 0xae || unicodeChar == 0x303d || unicodeChar == 0x3030 || unicodeChar == 0x2b55 || unicodeChar == 0x2b1c || unicodeChar == 0x2b1b || unicodeChar == 0x2b50) {
                                      result = YES;
                                  }
                              }
                          }];
    return result;
}

- (NSUInteger)glyphCount
{
    NSAttributedString * attributedSelf = [[NSAttributedString alloc] initWithString:self];
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef) attributedSelf);
    NSUInteger glyphCount = (NSUInteger)CTLineGetGlyphCount(line);
    CFRelease(line);
    return glyphCount;
}

@end
