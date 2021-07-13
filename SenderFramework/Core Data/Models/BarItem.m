//
//  BarItem.m
//  SENDER
//
//  Created by Roman Serga on 9/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "BarItem.h"
#import "ParamsFacade.h"


@implementation BarItem

@dynamic actions;
@dynamic itemID;
@dynamic icon;
@dynamic icon2;
@dynamic name;

@synthesize actionsParsed;

-(NSArray *)actionsParsed
{
    if (!actionsParsed)
    {
        if (self.actions)
            actionsParsed = [[ParamsFacade sharedInstance]arrayFromNSData:self.actions];
    }
    return actionsParsed;
}

-(BOOL)hasActionWithName:(NSString *)actionName
{
    BOOL hasAction = NO;
    for (NSDictionary * actionDictionary in self.actionsParsed)
    {
        if ([actionDictionary[@"oper"]isEqualToString:actionName])
        {
            hasAction = YES;
            break;
        }
    }
    return hasAction;
}

-(BOOL)hasFileAction
{
    BOOL hasAction = NO;
    for (NSDictionary * actionDictionary in self.actionsParsed)
    {
        if ([actionDictionary[@"oper"]isEqualToString:@"sendMedia"] && [actionDictionary[@"type"]isEqualToString:@"file"])
        {
            hasAction = YES;
            break;
        }
    }
    return hasAction;
}

-(BOOL)hasAudioAction
{
    BOOL hasAction = NO;
    for (NSDictionary * actionDictionary in self.actionsParsed)
    {
        if ([actionDictionary[@"oper"]isEqualToString:@"sendMedia"] && [actionDictionary[@"type"]isEqualToString:@"voice"])
        {
            hasAction = YES;
            break;
        }
    }
    return hasAction;
}

-(BOOL)hasCryptoAction
{
    return [self hasActionWithName:@"switchCrypto"];
}

-(BOOL)hasTextAction
{
    return [self hasActionWithName:@"sendMsg"];
}

-(BOOL)hasExpandedTextAction
{
    BOOL hasAction = NO;
    for (NSDictionary * actionDictionary in self.actionsParsed)
    {
        if ([actionDictionary[@"oper"] isEqualToString:@"sendMsg"])
        {
            hasAction = [actionDictionary[@"expand"] boolValue];
            break;
        }
    }
    return hasAction;
}

@end
