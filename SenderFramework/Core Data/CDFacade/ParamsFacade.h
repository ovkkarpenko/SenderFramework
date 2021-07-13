//
//  ParamsFacade.h
//  Sender
//
//  Created by Eugene Gilko on 8/20/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@interface ParamsFacade : NSObject <NSFetchedResultsControllerDelegate>

+ (ParamsFacade *)sharedInstance;

- (nonnull NSString *)buildNotificationStringFromUsersDictionariesArray:(NSArray *)users;
- (NSString *)buildStringFromUsersDictionariesArray:(NSArray *)users;
- (NSString *)buildStringFromUsersSet:(NSSet *)users;
- (NSData *)uiImageToNSData:(UIImage *)image;
- (UIImage *)nSDataToUIImage:(NSData*)imageData;
- (NSData *)nSdateFromArray:(NSArray *)array;
- (NSArray *)arrayFromNSData:(NSData *)data;

- (NSDictionary *)dictionaryFromNSData:(NSData *)data;
- (NSData *)NSDataFromNSDictionary:(NSDictionary *)dict;

- (NSString *)formattedStringFromNSDate:(NSDate *)date;
- (BOOL)compareTime:(NSDate *)first withTime:(NSDate *)second;
- (BOOL)compare3MinutesRange:(NSDate *)first withTime:(NSDate *)second;
- (NSString * _Nonnull)getDayAndMonthFromTime:(NSDate *)time;
- (NSArray *)getSortDescriptorsBy:(NSString *)sortTerm ascending:(BOOL)ascending;
- (CGSize)convertImageRectforMainWidth:(float)mainWidth forImage:(UIImage *)image;
- (NSInteger)chatCharsNumber:(NSString *)testStr;
- (BOOL)stringContainsEmoji:(NSString *)string;
- (BOOL)checkPhoneField:(UITextField *)textField range:(NSRange)range replacementString:(NSString *)string;
- (NSDate *)dateFromString:(NSString *)string;
- (NSString *)stringFromDate:(NSDate *)date;

@end
