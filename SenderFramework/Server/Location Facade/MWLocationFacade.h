//
// Created by Roman Serga on 24/3/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SenderFramework/MWLocationManager.h>

extern NSString * const MWLocationFacadeDidUpdateLocationNotification;
extern NSString * const MWLocationFacadeDidUpdateBLEPeripheralsNotification;

@interface MWLocationFacade : NSObject <MWLocationManagerDelegate>

+ (instancetype _Nonnull)sharedInstance;

@property (nonatomic, strong) MWLocationManager * locationManager;

/*
 * If user has decided whether allow SENDER to use location or not, method synchronously calls resultBlock.
 * Otherwise, method requests user's permission to use location and asynchronously calls resultBlock on main thread.
 */
- (void)isLocationUsageAllowed:(void(^_Nonnull)(BOOL))resultBlock;
- (NSDictionary<NSString *, NSString *> *)locationDictionary;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

- (void)startUpdatingBLEPeripherals;
- (void)stopUpdatingBLEPeripherals;

@property (nonatomic) BOOL sendLocationUpdatesToServer;

@end