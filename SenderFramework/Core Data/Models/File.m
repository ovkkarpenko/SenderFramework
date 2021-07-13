//
//  File.m
//  SENDER
//
//  Created by Nick Gromov on 10/27/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "File.h"

@implementation File

@dynamic name;
@dynamic type;
@dynamic desc;
@dynamic url;
@dynamic from;
@dynamic fromName;
@dynamic isDownloaded;
@dynamic prev_url;
@dynamic localUrl;

@synthesize duration;

- (void)setDataFromDictionary:(NSDictionary *)data
{
    self.name = data[@"name"];
    self.type = data[@"type"];
    self.desc = data[@"desc"];
    self.url = data[@"url"];
    if (data[@"preview"]) {
        self.prev_url = data[@"preview"];
    }
    else {
        self.prev_url = data[@"url"];
    }
    
    if (data[@"length"]) {
        NSString * durstring = [NSString stringWithFormat:@"%.2f",[data[@"length"] floatValue]];
        durstring = [durstring stringByReplacingOccurrencesOfString:@"." withString:@":"];
        self.desc = durstring;
    }
}

- (NSString *)getFilePathName
{
    if (!self.url)
        return nil;
    if ([self.url hasPrefix:@"assets-library://"])
    {
        NSArray * subs = [self.url componentsSeparatedByString:@"/"];
        return [subs lastObject];
    }
    else
    {
        NSArray * subs = [self.url componentsSeparatedByString:@"."];
        return [[NSString stringWithFormat:@"%lu",(unsigned long)[self.url hash]]stringByAppendingPathExtension:[subs lastObject]];
    }
}

@end
