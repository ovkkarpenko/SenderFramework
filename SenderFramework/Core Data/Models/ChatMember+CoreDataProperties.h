//
//  ChatMember+CoreDataProperties.h
//  
//
//  Created by Roman Serga on 21/2/17.
//
//

#import "ChatMember+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ChatMember (CoreDataProperties)

+ (NSFetchRequest<ChatMember *> *)fetchRequest;

@property (nullable, nonatomic, copy, readonly) NSNumber *roleRaw;
@property (nonnull, nonatomic, retain) Contact *contact;
@property (nullable, nonatomic, retain) Dialog *chat;

@end

NS_ASSUME_NONNULL_END
