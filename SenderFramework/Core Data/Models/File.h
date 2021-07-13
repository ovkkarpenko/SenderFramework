//
//  File.h
//  SENDER
//
//  Created by Nick Gromov on 10/27/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface File : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * prev_url;
@property (nonatomic, retain) NSString * localUrl;
@property (nonatomic, retain) NSString * from;
@property (nonatomic, retain) NSString * fromName;
@property (nonatomic, retain) NSNumber * isDownloaded;

//Not in DB
@property (nonatomic, strong) NSString * duration;

- (void)setDataFromDictionary:(NSDictionary *)data;
- (NSString *)getFilePathName;
- (NSURL *)getFileUrl;

//Returns URL created by [NSURL fileURLWithPath:]
- (NSURL *)getLocalFileURL;

@end
