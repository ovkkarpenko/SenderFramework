//
//  ChatMember+CoreDataClass.h
//  
//
//  Created by Roman Serga on 21/2/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Contact, Dialog;

typedef NS_ENUM(NSInteger, ChatMemberRole) {
    ChatMemberRoleUser = 0,
    ChatMemberRoleAdmin = 1
};

NS_ASSUME_NONNULL_BEGIN

@interface ChatMember : NSManagedObject

@property (nonatomic) ChatMemberRole role;

@end

NS_ASSUME_NONNULL_END

#import "ChatMember+CoreDataProperties.h"
