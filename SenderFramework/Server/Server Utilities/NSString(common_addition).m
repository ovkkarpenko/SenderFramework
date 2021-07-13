//
//  NSString(common_addition).m
//  Privat24
//
//  Created by Leonid Lo on 2/27/12.
//  Copyright (c) 2012 Middleware Inc. All rights reserved.
//

#import "NSString(common_addition).h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (common_addition)

- (NSString *)MD5String {
	const char *cMD5String = [self UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(cMD5String,(CC_LONG)strlen(cMD5String), result);
	
	NSString *MD5String = [NSString stringWithFormat:
                           @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                           result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
                           result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
	
	return MD5String;
}

-(NSString *)SHA1_
{
    if (!self.length)
    {
        return @"";
    }
    const char *cstr = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:self.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return [output stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (BOOL)isEmailValid
{
	NSString* candidate = [self trim];
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
	
    return [emailTest evaluateWithObject:candidate];
}

- (NSString *)trim {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isPasswordValid {
	NSString *pass = [self trim];
	return [pass length] > 0;
}


#pragma mark -

#define LENG 64

- (NSString *)stringAsPhone {
	NSString * str = [self trim];
	
	if ([str length]<5) {
		//	too short for phone number
		return nil;
	}

	NSData *bytes = [str dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	if ([bytes length] > LENG-2) {
		return nil;
	}
	
	char outBuff[LENG];
	memset(outBuff, 0, LENG);
	outBuff[0] = '+';
	char *pOutBuff = outBuff + 1;
	int j=0;
	const char *inChar = [bytes bytes];
	
	for (int i=0; i<[bytes length]; ++i) {
		const char ch = inChar[i];
		
		if ((ch >= '0') && (ch <= '9')) {
			pOutBuff[j++] = ch;
			continue;
		}
		
		if (ch == '+') {
			if (i == 0) {
				continue;
			}
			//	'+' can be at the beginning only
			pOutBuff = nil;
			break;
		}
		
		if (ch == '(' || ch == ')' || ch == '-' || ch == ' ') {
			continue;
		}

		//	wrong symbol to be within a phone number
		pOutBuff = nil;
		break;
	}

	NSString *phone = nil;
	if (pOutBuff) {
		if (j >= 1) {
			//	add '+' symbol at the beginning
			pOutBuff = outBuff;            
		}
		phone = [NSString stringWithCString:pOutBuff encoding:NSASCIIStringEncoding];
	}
	return phone;
}

- (NSString *)stringAsLogin {
	NSString *str = [self trim];
	
	if ([str length] < 1) {
		//	too short for login
		return nil;
	}
	
	for (int i=0; i< [str length]; ++i) {
		NSRange range = NSMakeRange(i, 1);
		NSString *symbol = [str substringWithRange:range];
		
		if (NSNotFound != [symbol rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location) {
			if (i==0) {
				//	first symbol cannot be a digit
				return nil;
			}
			continue;
		}
		
		if (NSNotFound != [symbol rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location) {
			continue;
		}
		
		//	wrong symbol (neither digit nor alphabetical char)
		return nil;
	}
	return str;
}


#undef LENG

/** 
 ++ by vpv - add - INN = АБВГДЕЖЗИК
 К = Остаток от деления (-1*А +5*Б + 7*В + 9*Г + 4*Д + 6*Е + 10*Ж + 5*З + 7*И) / 11
 Leonid: the method was copy-pasted from Tools.m (aka +(BOOL) checkInnChecksum:(NSString*)string;)

*/

- (BOOL)isInnValid {
	
	NSString *string = [self trim];
	
	if (10!= [string length]) {
		return NO;
	}
	
    if ([string isEqualToString:@"0000000000"]) {
		return YES;
	}
    
    int mult[9] = { -1, 5, 7, 9, 4, 6, 10, 5, 7 };
    int sum = 0;
    
    for (int i = 0; i<9; i++) {
        int tmp = [[string substringWithRange:NSMakeRange(i, 1)] intValue];
        sum = sum + mult[i] * tmp;
    }
    
    int tenth = [[string substringFromIndex:9] intValue];
    
    return (BOOL)( (sum % 11) % 10 == tenth );
}


- (NSString *)stringAsCurrency
{
    NSString* result = nil;
    NSMutableArray* componentsArray = [[self componentsSeparatedByString:@"."] mutableCopy];
    if (componentsArray.count < 2)
    {
        return self;
    }
    NSString* secondPart = [componentsArray objectAtIndex:1];
//    secondPart = [secondPart stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"0"]];
//    switch (secondPart.length)
//    {
//        case 0:
//            secondPart = @"00";
//            break;
//        case 1:
//            secondPart = [secondPart stringByAppendingString:@"0"];
//        default:
//            break;
//    }

    BOOL notFinish = YES;
    while (secondPart.length > 2 && notFinish)
    {
        if ([secondPart hasSuffix:@"0"])
        {
            secondPart = [secondPart substringToIndex:secondPart.length - 1];
        }
        else
        {
            notFinish = NO;
        }
    }
    [componentsArray replaceObjectAtIndex:1 withObject:secondPart];
    result = [componentsArray componentsJoinedByString:@"."];
    return result;
}


@end
