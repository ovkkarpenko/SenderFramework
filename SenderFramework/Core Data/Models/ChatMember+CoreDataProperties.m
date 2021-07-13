//
//  ChatMember+CoreDataProperties.m
//  
//
//  Created by Roman Serga on 21/2/17.
//
//

#import "ChatMember+CoreDataProperties.h"

@implementation ChatMember (CoreDataProperties)

+ (NSFetchRequest<ChatMember *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ChatMember"];
}

@dynamic roleRaw;
@dynamic contact;
@dynamic chat;

@end
