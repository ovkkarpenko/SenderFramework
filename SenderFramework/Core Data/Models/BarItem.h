//
//  BarItem.h
//  SENDER
//
//  Created by Roman Serga on 9/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BarItem : NSManagedObject

@property (nonatomic, retain) NSData * actions;
@property (nonatomic, retain) NSString * itemID;
@property (nonatomic, retain) NSString * icon;
@property (nonatomic, retain) NSString * icon2;
@property (nonatomic, retain) NSData * name;

@property (nonatomic, retain, readonly) NSArray * actionsParsed;

-(BOOL)hasFileAction;
-(BOOL)hasAudioAction;
-(BOOL)hasCryptoAction;
-(BOOL)hasTextAction;
-(BOOL)hasExpandedTextAction;

@end
