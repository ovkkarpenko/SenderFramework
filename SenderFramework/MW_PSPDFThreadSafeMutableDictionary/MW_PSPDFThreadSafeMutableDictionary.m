//
//  PSPDFThreadSafeMutableDictionary.m
//  PSPDFKit
//
//  Copyright (c) 2013 PSPDFKit GmbH. All rights reserved.
//

#import "MW_PSPDFThreadSafeMutableDictionary.h"
#import <libkern/OSAtomic.h>

#define MW_LOCKED(...) OSSpinLockLock(&_lock); \
__VA_ARGS__; \
OSSpinLockUnlock(&_lock);

@implementation MW_PSPDFThreadSafeMutableDictionary {
    OSSpinLock _lock;
    NSMutableDictionary *_dictionary; // Class Cluster!
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)init {
    return [self initWithCapacity:0];
}

- (id)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys {
    if ((self = [self initWithCapacity:objects.count])) {
        [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            _dictionary[keys[idx]] = obj;
        }];
    }
    return self;
}

- (id)initWithCapacity:(NSUInteger)capacity {
    if ((self = [super init])) {
        _dictionary = [[NSMutableDictionary alloc] initWithCapacity:capacity];
        _lock = OS_SPINLOCK_INIT;
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSMutableDictionary

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    MW_LOCKED(_dictionary[aKey] = anObject)
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
    MW_LOCKED([_dictionary addEntriesFromDictionary:otherDictionary]);
}

- (void)setDictionary:(NSDictionary *)otherDictionary {
    MW_LOCKED([_dictionary setDictionary:otherDictionary]);
}

- (void)removeObjectForKey:(id)aKey {
    MW_LOCKED([_dictionary removeObjectForKey:aKey])
}

- (void)removeAllObjects {
    MW_LOCKED([_dictionary removeAllObjects]);
}

- (NSUInteger)count {
    MW_LOCKED(NSUInteger count = _dictionary.count)
    return count;
}

- (NSArray *)allKeys {
    MW_LOCKED(NSArray *allKeys = _dictionary.allKeys)
    return allKeys;
}

- (NSArray *)allValues {
    MW_LOCKED(NSArray *allValues = _dictionary.allValues)
    return allValues;
}

- (id)objectForKey:(id)aKey {
    MW_LOCKED(id obj = _dictionary[aKey])
    return obj;
}

- (NSEnumerator *)keyEnumerator {
    MW_LOCKED(NSEnumerator *keyEnumerator = [_dictionary keyEnumerator])
    return keyEnumerator;
}

- (id)copyWithZone:(NSZone *)zone {
    return [self mutableCopyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    MW_LOCKED(id copiedDictionary = [[self.class allocWithZone:zone] initWithDictionary:_dictionary])
    return copiedDictionary;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len {
    MW_LOCKED(NSUInteger count = [[_dictionary copy] countByEnumeratingWithState:state objects:stackbuf count:len]);
    return count;
}

- (void)performLockedWithDictionary:(void (^)(NSDictionary *dictionary))block {
    if (block) MW_LOCKED(block(_dictionary));
}

- (BOOL)isEqual:(id)object {
    if (object == self) return YES;

    if ([object isKindOfClass:MW_PSPDFThreadSafeMutableDictionary.class]) {
        MW_PSPDFThreadSafeMutableDictionary *other = object;
        __block BOOL isEqual = NO;
        [other performLockedWithDictionary:^(NSDictionary *dictionary) {
            [self performLockedWithDictionary:^(NSDictionary *otherDictionary) {
                isEqual = [dictionary isEqual:otherDictionary];
            }];
        }];
        return isEqual;
    }
    return NO;
}

@end