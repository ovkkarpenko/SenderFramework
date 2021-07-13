//
//  ChatMember+CoreDataClass.m
//  
//
//  Created by Roman Serga on 21/2/17.
//
//

#import "ChatMember+CoreDataClass.h"
#import "Contact.h"
#import "Dialog.h"

@interface ChatMember()

@property (nullable, nonatomic, copy, readwrite) NSNumber *roleRaw;

@end

@implementation ChatMember

@dynamic roleRaw;

-(void)setRole:(ChatMemberRole)role
{
    self.roleRaw = @(role);
}

-(ChatMemberRole)role
{
    return (ChatMemberRole)[self.roleRaw integerValue];
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingRole
{
    return [NSSet setWithObject:@"roleRaw"];
}

- (void)prepareForDeletion
{
    if (self.contact.memberRepresentations)
    {
        if (self.contact.memberRepresentations.count == 1)
        {
            ChatMember * onlyMemberRepresentation = [self.contact.memberRepresentations anyObject];
            if ([onlyMemberRepresentation isEqual:self])
                [self.contact.managedObjectContext deleteObject:self.contact];
        }
    }
    else
    {
        [self.contact.managedObjectContext deleteObject:self.contact];
    }
}

@end
