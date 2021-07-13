//
//  MWLocationManager.h
//  SENDER
//
//  Created by Eugene on 11/17/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void (^RequestLocationAccessCompletion)(CLAuthorizationStatus);

@class MWLocationManager;

@protocol MWLocationManagerDelegate <NSObject>

@optional

- (void)locationManagerDidUpdateLocation:(MWLocationManager *)locationManager;
- (void)locationManager:(MWLocationManager *)locationManager didDiscoverBLEPeripheral:(NSDictionary *)peripheral;

@end

@interface MWLocationManager : NSObject <CLLocationManagerDelegate, CBCentralManagerDelegate>

@property (nonatomic, strong, readonly, nonnull) NSString * latitude;
@property (nonatomic, strong, readonly, nonnull) NSString * longitude;

@property (nonatomic, weak) id<MWLocationManagerDelegate> delegate;

@property (nonatomic, readonly) BOOL isBLEScanningActive;

@property (nonatomic, readonly) CLLocationDistance distanceFilter;
@property (nonatomic, readonly) CLAuthorizationStatus authorizationStatus;
@property (nonatomic, readonly) CBManagerState bleState;

/*
 * Checks whether location services is enabled on device
 */
@property (nonatomic, readonly) BOOL isLocationServicesEnabled;

- (instancetype)initWithDistanceFilter:(CLLocationDistance)distanceFilter;

- (CLLocation *)deviceLocation;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

/*
 * If current bleState != CBManagerStatePoweredOn,
 * BLE scanning becomes active after bleState changes to CBManagerStatePoweredOn.
 */
- (void)startBLEScanning;
- (void)stopBLEScanning;

/*
 * Method does nothing if authorizationStatus is not kCLAuthorizationStatusNotDetermined or
 * MWLocationManager is currently requesting location access
 */
- (void)requestLocationAccessWithCompletion:(RequestLocationAccessCompletion)completion;

@end
