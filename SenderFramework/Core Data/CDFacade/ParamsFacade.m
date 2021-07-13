//
//  ParamsFacade.m
//  Sender
//
//  Created by Eugene Gilko on 8/20/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "ParamsFacade.h"
#import "CoreDataFacade.h"
#import "Contact.h"
#import "Settings.h"
#import "Owner.h"

static ParamsFacade* instance = nil;

@implementation ParamsFacade

- (nonnull NSString *)buildNotificationStringFromUsersDictionariesArray:(NSArray *)users
{
    NSMutableArray * usersNames = [NSMutableArray array];
    for (NSDictionary * user in users)
    {
        if (![user[@"userId"] isEqualToString:[CoreDataFacade sharedInstance].ownerUDIDString])
        {
            if (user[@"name"])
                [usersNames addObject:user[@"name"]];
        }
    }
    NSString * names = [usersNames componentsJoinedByString:@", "];
    return [names isEqualToString:@""] ? SenderFrameworkLocalizedString(@"unknown_user", nil) : names;
}


- (NSString *)buildStringFromUsersDictionariesArray:(NSArray *)users
{
    NSString *result = [NSString string];
    if ([users count] >= 1)
    {
        if ([[CoreDataFacade sharedInstance]selectContactById:users[0][@"userId"]]){
            NSString * name = [[CoreDataFacade sharedInstance]selectContactById:users[0][@"userId"]].name;
            if (name)
                result = [result stringByAppendingString:name];
        }
        
        if ([users count] > 1)
        {
            for (int index = 1; index < [users count]; index++)
            {
                if ([[CoreDataFacade sharedInstance]selectContactById:users[index][@"userId"]].name)
                     result = [result stringByAppendingString:[NSString stringWithFormat:@", %@", [[CoreDataFacade sharedInstance]selectContactById:users[index][@"userId"]].name]];
            }
        }
    }
    return [result isEqualToString:@""] ? SenderFrameworkLocalizedString(@"unknown_user", nil) : result;
}

- (NSString *)buildStringFromUsersSet:(NSSet *)users
{
    NSString *result = [NSString string];
    if ([users count] == 1)
    {
        result = [(Contact *)users.anyObject name];
    }
    else if ([users count] > 1)
    {
        for (Contact * user in users)
            result = [result stringByAppendingString:[NSString stringWithFormat:@"%@, ", user.name]];
        result = [result stringByReplacingCharactersInRange:NSMakeRange((result.length - 2), 2) withString:@""];
    }
    return result;
}


+ (ParamsFacade *)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[ParamsFacade alloc] init];
    });
    
    return instance;
}

- (NSArray *)getSortDescriptorsBy:(NSString *)sortTerm ascending:(BOOL)ascending {
    NSMutableArray * sortDescriptors = [[NSMutableArray alloc] init];
    NSArray * sortKeys = [sortTerm componentsSeparatedByString:@","];
    for (NSString * sortKey in sortKeys)
    {
        NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:ascending];
        [sortDescriptors addObject:sortDescriptor];
    }
    return sortDescriptors;
}

- (NSString *)formattedStringFromNSDate:(NSDate *)date
{
    NSDateFormatter * df_utc = [[NSDateFormatter alloc] init];
    [df_utc setTimeZone:[NSTimeZone localTimeZone]];
    NSString * testFormat = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    BOOL is24HoursTime = ![testFormat containsString:@"a"];
    [df_utc setDateFormat:is24HoursTime ? @"HH:mm" : @"hh:mm a"];
    
    return [df_utc stringFromDate:date];
}

- (NSDate *)dateFromString:(NSString *)string
{
    static NSDateFormatter * formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMdd"];
    });
    return [formatter dateFromString:string];
}

- (NSString *)stringFromDate:(NSDate *)date
{
    static NSDateFormatter * formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yyyy"];
    });
    return [formatter stringFromDate:date];
}

#pragma mark CONVERTORS TO DATA

- (NSData *)uiImageToNSData:(UIImage *)image
{
    return UIImagePNGRepresentation(image);
}

- (UIImage *)nSDataToUIImage:(NSData*)imageData
{
    if (!imageData)
        return nil;
    return [UIImage imageWithData:imageData];
}

- (NSData *)nSdateFromArray:(NSArray *)array
{
    return [NSKeyedArchiver archivedDataWithRootObject:array];
}

- (NSArray *)arrayFromNSData:(NSData *)data
{
    if (!data)
        return nil;
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (NSDictionary *)dictionaryFromNSData:(NSData *)data
{
    if (!data || ![data isKindOfClass:[NSData class]])
        return nil;

    return [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingMutableLeaves|NSJSONReadingMutableContainers
                                             error:nil];
}

- (NSData *)NSDataFromNSDictionary:(NSDictionary *)dict
{
    NSData * data = [NSData data];
    
    @try {
        data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    
    return data;
}

- (BOOL)compareTime:(NSDate *)first withTime:(NSDate *)second
{
    if (!first) {
        return YES;
    }
    NSDateComponents * components1 = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:first];
    NSDateComponents * components2 = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:second];
    
    if ([components2 year] > [components1 year]) {
        return YES;
    }
    else if ([components2 month] > [components1 month]) {
         return YES;
    }
    else if ([components2 day] > [components1 day]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)compare3MinutesRange:(NSDate *)first withTime:(NSDate *)second
{
    if (!first) {
        return NO;
    }
    
    NSDateComponents * components1 = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:first];
    NSDateComponents * components2 = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:second];
    
    if ([components2 minute] > [components1 minute] + 1.0) {
        return NO;
    }
    
    if ([components2 year] > [components1 year])
        return NO;
    if ([components2 month] > [components1 month])
        return NO;
    if ([components2 day] > [components1 day])
        return NO;
    if ([components2 hour] > [components1 hour])
        return NO;

    return YES;
}

- (NSString * _Nonnull)getDayAndMonthFromTime:(NSDate *)time
{
    if (!time) return SenderFrameworkLocalizedString(@"today",nil);

    NSDate * today = [NSDate date];
    NSCalendarUnit calendarComponents = NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
    NSDateComponents * components1 = [[NSCalendar currentCalendar] components:calendarComponents fromDate:time];
    NSDateComponents * components2 = [[NSCalendar currentCalendar] components:calendarComponents fromDate:today];
    
    if ([components1 day] == [components2 day] &&
        [components1 month] == [components2 month] &&
        [components1 year] == [components2 year]) {
        return SenderFrameworkLocalizedString(@"today",nil);
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

    NSString * appLocale = [[[[CoreDataFacade sharedInstance] getOwner] settings] language];
    [formatter setLocale:[NSLocale localeWithLocaleIdentifier:appLocale]];
    [formatter setDateFormat:@"MMMM"];

    NSString * month = [formatter stringFromDate:time];
    
    NSDateComponents * components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:time];;
    
    return  [NSString stringWithFormat:@"%li %@",(long)[components day], month];
    
}

- (CGSize)convertImageRectforMainWidth:(float)mainWidth forImage:(UIImage *)image
{
    float scaleCooficient = mainWidth / image.size.width;
    float correctedHeight = image.size.height * scaleCooficient;
    return CGSizeMake(mainWidth, correctedHeight);
}

- (NSInteger)chatCharsNumber:(NSString *)testStr
{
    __block NSInteger length = 0;
    [testStr enumerateSubstringsInRange:NSMakeRange(0, [testStr length] - 1)
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                length++;
                            }];
    return length > 0 ? (NSInteger)length : [testStr length];
}

- (BOOL)stringContainsEmoji:(NSString *)string
{
    __block BOOL returnValue = NO;
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length]) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
     ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
         
         const unichar hs = [substring characterAtIndex:0];
         // surrogate pair
         
         if (0xd800 <= hs && hs <= 0xdbff) {
             if (substring.length > 1) {
                 const unichar ls = [substring characterAtIndex:1];
                 const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                 if (0x1d000 <= uc && uc <= 0x1f77f) {
                     returnValue = YES;
                 }
             }
         } else if (substring.length > 1) {
             const unichar ls = [substring characterAtIndex:1];
             if (ls == 0x20e3) {
                 returnValue = YES;
             }
             else if ((0x2702 <= hs && hs <= 0x27B0) || hs == 0x263a) {
                 returnValue = YES;
             }
             
        } else {
             // non surrogate
             if (0x2100 <= hs && hs <= 0x27ff) {
                 returnValue = YES;
             } else if (0x2B05 <= hs && hs <= 0x2b07) {
                 returnValue = YES;
             } else if (0x2B05 <= hs && hs <= 0x2b07) {
                 returnValue = YES;
             } else if (0x2934 <= hs && hs <= 0x2935) {
                 returnValue = YES;
             } else if (0x3297 <= hs && hs <= 0x3299) {
                 returnValue = YES;
             } else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 || hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
                 returnValue = YES;
             }
         }
     }];
    
    return returnValue;
}

- (BOOL)checkPhoneField:(UITextField *)textField range:(NSRange)range replacementString:(NSString *)string
{
    if (range.length && [string isEqualToString:@""]) {
        return true;
    }
    
    if (string.length > 1) {
        string = [string stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [string length])];
        
        if (textField.text.length == 1 && ![[string substringToIndex:1] isEqualToString:@"+"]) {
            string = [NSString stringWithFormat:@"+%@",string];
        }
        
        textField.text = string;
    }
    
    NSString * strRezult = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if ([strRezult isEqualToString:@"+"] || strRezult.length == 0) {
        return true;
    }
    else if (strRezult.length == 1) {
        int ch = (int)[strRezult characterAtIndex:0];
        
        if (ch >= 48 && ch <= 57) {
            strRezult = [NSString stringWithFormat:@"+%@",strRezult];
            textField.text = @"+";
            return true;
        }
    }
    
    NSString * strippedNumber = [strRezult stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [strRezult length])];
    
    if(strRezult.length > 1 && strRezult.length < 16 && [strippedNumber integerValue] > 0 && [[strRezult substringToIndex:1] isEqualToString:@"+"] ) {
        return true;
    }
    
    return false;
}

@end
