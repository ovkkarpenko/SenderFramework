//
//  MWLocationManager.m
//  SENDER
//
//  Created by Eugene on 11/17/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "MWLocationManager.h"
#import "ServerFacade.h"
#import "Owner.h"
#import "Settings.h"

@interface MWLocationManager ()

@property (nonatomic, retain) CLLocationManager * locationManager;

@property (strong, nonatomic) CLBeaconRegion * beaconRegion;
@property (strong, nonatomic) NSDictionary * beaconPeripheralData;
@property (strong, nonatomic) CBPeripheralManager * peripheralManager;
@property (nonatomic, strong) CBCentralManager *bluetoothManager;

@property (nonatomic, readwrite) BOOL isBLEScanningActive;

@property (nonatomic, copy) RequestLocationAccessCompletion requestLocationAccessCompletion;

@end

@implementation MWLocationManager


- (instancetype)init
{
    return [self initWithDistanceFilter:50];
}

- (instancetype)initWithDistanceFilter:(CLLocationDistance)distanceFilter
{
    self = [super init];
    if (self)
    {
        self.locationManager = [[CLLocationManager alloc] init];

        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = distanceFilter;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        self.locationManager.pausesLocationUpdatesAutomatically = YES;
    }
    return self;
}

- (CLAuthorizationStatus)authorizationStatus
{
    return [CLLocationManager authorizationStatus];
}

- (CBManagerState)bleState
{
    return self.bluetoothManager != nil ? self.bluetoothManager.state : CBManagerStateUnknown;
}

- (void)requestLocationAccessWithCompletion:(RequestLocationAccessCompletion)completion
{
    if ([self authorizationStatus] != kCLAuthorizationStatusNotDetermined) return;
    if (self.requestLocationAccessCompletion) return;
    self.requestLocationAccessCompletion = completion;
    [self.locationManager requestWhenInUseAuthorization];
}

- (CLLocationDistance)distanceFilter
{
    return self.locationManager.distanceFilter;
}

- (BOOL)isLocationServicesEnabled
{
    return [CLLocationManager locationServicesEnabled];
}

- (NSString *)latitude
{
    CLLocationCoordinate2D coordinates = self.locationManager.location.coordinate;
    return coordinates.latitude ? [NSString stringWithFormat:@"%f", coordinates.latitude] : @"";
}

- (NSString *)longitude
{
    CLLocationCoordinate2D coordinates = self.locationManager.location.coordinate;
    return coordinates.longitude ? [NSString stringWithFormat:@"%f", coordinates.longitude] : @"";
}

- (CLLocation *)deviceLocation
{
    return self.locationManager.location;
}

- (void)startUpdatingLocation
{
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation
{
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // NSLog(@"didFailWithError: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation * lastLocation = [locations lastObject];
    [NSString stringWithFormat:@"%f", lastLocation.coordinate.latitude];
    [NSString stringWithFormat:@"%f", lastLocation.coordinate.longitude];
    LLog(@"Received new locations: %@", locations);
    if ([self.delegate respondsToSelector:@selector(locationManagerDidUpdateLocation:)])
        [self.delegate locationManagerDidUpdateLocation:self];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (self.requestLocationAccessCompletion)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.requestLocationAccessCompletion(status);
            self.requestLocationAccessCompletion = nil;
        });
    }
}

#pragma mark - Beacons Location

- (void)startBLEScanning
{
    if (!self.bluetoothManager)
    {
        self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.bluetoothManager.delegate = self;
    }
    self.isBLEScanningActive = YES;
    if (self.bleState != CBManagerStatePoweredOn) return;
    NSDictionary * options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @NO};
    [self.bluetoothManager scanForPeripheralsWithServices:nil options:options];
}

- (void)stopBLEScanning
{
    self.isBLEScanningActive = NO;
    [self.bluetoothManager stopScan];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBManagerStatePoweredOff:
            // NSLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBManagerStatePoweredOn:
            // NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            break;
        case CBManagerStateResetting:
            // NSLog(@"CoreBluetooth BLE hardware is resetting");
            break;
        case CBManagerStateUnauthorized:
            // NSLog(@"CoreBluetooth BLE state is unauthorized");
            break;
        case CBManagerStateUnknown:
            // NSLog(@"CoreBluetooth BLE state is unknown");
            break;
        case CBManagerStateUnsupported:
            // NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
            break;
        default:
            break;
    }
    if (self.bleState != CBManagerStatePoweredOn)
        [self stopBLEScanning];
    else if (self.isBLEScanningActive)
        [self startBLEScanning];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSString * stringRep = peripheral.identifier.UUIDString;
    NSDictionary * peripheralDictionary = @{@"mac": stringRep, @"RSSI": RSSI};
    LLog(@"Did discover peripheral. peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ",
            peripheral, RSSI, stringRep, advertisementData);
    if ([self.delegate respondsToSelector:@selector(locationManager:didDiscoverBLEPeripheral:)])
        [self.delegate locationManager:self didDiscoverBLEPeripheral:peripheralDictionary];
}

@end
