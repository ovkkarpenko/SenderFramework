//
// Created by Roman Serga on 24/3/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "MWLocationFacade.h"
#import "CoreDataFacade.h"
#import "Owner.h"
#import "Settings.h"
#import "ServerFacade.h"

#ifndef dispatch_main_sync_safe
#define dispatch_main_sync_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }
#endif

NSString * const MWLocationFacadeDidUpdateLocationNotification = @"MWLocationFacadeDidUpdateLocationNotification";
NSString * const MWLocationFacadeDidUpdateBLEPeripheralsNotification = @"MWLocationFacadeDidUpdateBLEPeripheralsNotification";

@interface MWLocationFacade ()

@property (nonatomic, strong) NSMutableArray * blePeripherals;
@property (nonatomic) NSInteger maxPeripheralsCount;

@end

@implementation MWLocationFacade
{

}

+ (instancetype)sharedInstance
{
    static MWLocationFacade * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MWLocationFacade alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.locationManager = [[MWLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.blePeripherals = [NSMutableArray array];
        self.maxPeripheralsCount = 30;
    }
    return self;
}

- (void)isLocationUsageAllowed:(void (^ _Nonnull)(BOOL))resultBlock
{
    CLAuthorizationStatus authorizationStatus = [self.locationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusNotDetermined)
    {
        [self.locationManager requestLocationAccessWithCompletion:^(CLAuthorizationStatus status) {
            BOOL isLocationEnabled = [self isLocationEnabledStatus:status];
            DBSettings.location = @(isLocationEnabled);
            resultBlock(isLocationEnabled);
        }];
    }
    else
    {
        resultBlock([self isLocationEnabledStatus:authorizationStatus]);
    }
}

- (NSDictionary *)locationDictionary
{
    __block BOOL locationEnabled;
    dispatch_main_sync_safe(^{ locationEnabled = [DBSettings.location boolValue]; });
    NSString * latitude = locationEnabled ? self.locationManager.latitude : @"";
    NSString * longitude = locationEnabled ? self.locationManager.longitude : @"";
    return @{@"lt": latitude, @"ln": longitude};
}

- (BOOL)isLocationEnabledStatus:(CLAuthorizationStatus) status
{
    return status == kCLAuthorizationStatusAuthorizedAlways ||
            status == kCLAuthorizationStatusAuthorizedWhenInUse ||
            status == kCLAuthorizationStatusAuthorized;
}

- (void)startUpdatingLocation
{
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation
{
    [self.locationManager stopUpdatingLocation];
}

- (void)startUpdatingBLEPeripherals
{
    [self.locationManager startBLEScanning];
    [self startBLEUpdatesSendingTimer];
}

- (void)startBLEUpdatesSendingTimer
{
    [NSTimer scheduledTimerWithTimeInterval:30
                                     target:self
                                   selector:@selector(sendBLEAndLocation)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)stopUpdatingBLEPeripherals
{
    [self.locationManager stopBLEScanning];
}

- (void)setSendLocationUpdatesToServer:(BOOL)sendLocationUpdatesToServer
{
    _sendLocationUpdatesToServer = sendLocationUpdatesToServer;

}

- (void)sendBLEAndLocation
{
    if (self.blePeripherals.count)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:MWLocationFacadeDidUpdateBLEPeripheralsNotification
                                                            object:self
                                                          userInfo:@{@"peripherals": [self.blePeripherals copy]}];
        if (self.sendLocationUpdatesToServer) [self sendLocationUpdate];
        if (self.blePeripherals.count > self.maxPeripheralsCount) [self.blePeripherals removeAllObjects];
    }
}

- (void)sendLocationUpdate
{
    NSMutableDictionary * locationDictionary = [[self locationDictionary] mutableCopy];
    if (self.blePeripherals.count)
        locationDictionary[@"bleList"] = [self.blePeripherals copy];
    [[ServerFacade sharedInstance] sendMyLocation:locationDictionary completionHandler:nil];
}

#pragma mark - MWLocationManager Delegate

- (void)locationManagerDidUpdateLocation:(MWLocationManager *)locationManager
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MWLocationFacadeDidUpdateLocationNotification
                                                        object:self
                                                      userInfo:self.locationDictionary];
    if (self.sendLocationUpdatesToServer) [self sendLocationUpdate];
}

- (void)locationManager:(MWLocationManager *)locationManager didDiscoverBLEPeripheral:(NSDictionary *)peripheral
{
    [self.blePeripherals addObject:peripheral];
}

@end