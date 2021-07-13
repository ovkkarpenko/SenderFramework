//
//  LogEvent.m
//  SENDER
//
//  Created by Eugene Gilko on 12/9/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "LogEvent.h"
#import "ParamsFacade.h"

@implementation LogEvent

- (void)addEvent:(NSDictionary *)newEvent
{
    self.eventtime = [NSDate date];
    self.eventdata = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:newEvent];
}

@end
