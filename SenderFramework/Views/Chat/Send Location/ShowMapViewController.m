//
//  ShowMapViewController.m
//  SENDER
//
//  Created by Eugene on 11/21/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "ShowMapViewController.h"
#import <AddressBookUI/AddressBookUI.h>
#import "PBConsoleConstants.h"
#import "UIImage+Resize.h"
#import "UIAlertView+CompletionHandler.h"
#import "ServerFacade.h"
#import "MWLocationFacade.h"
#import <SenderFramework/SenderFramework-Swift.h>

const NSString * locationSelectAnnotationViewIdentifier = @"LocationSelectAnnotationViewIdentifier";

@interface ShowMapViewController ()
{
    IBOutlet MWUniversalMapView * mapView;
    IBOutlet UIButton * setDefaultLocationButton;
    IBOutlet UIButton * cancelButton;
    CLLocation * userCoordinates;
    CLLocation * currentCoordinates;
    NSString * description;
    
    NSTimer * updateLocationTimer;
}

@end

@implementation ShowMapViewController

- (NSBundle *)nibBundle
{
    return NSBundle.senderFrameworkResourcesBundle;
}

- (NSString *)nibName
{
    return @"ShowMapViewController";
}

- (IBAction)setDefaultLocationAction:(id)sender
{
    [[MWLocationFacade sharedInstance] isLocationUsageAllowed:^(BOOL locationAllowed) {
        if (locationAllowed)
            [self showMapAtZoom:0.01 andLocation:userCoordinates];
        else
            [self showLocationNotAvailableAlert];
    }];
}

- (void)showLocationNotAvailableAlert
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"error_location_not_available", nil)
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil];

    UIAlertAction * goToSettingsAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"error_location_not_available_go_to_settings", nil)
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                                }];
    [alert addAction:goToSettingsAction];
    [alert addAction:okAction];
    [alert mw_safePresentInViewController:self animated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)cancelAction:(id)sender
{
    [self.delegate showMapViewController:self
               didFinishEnteringLocation:nil
                               withImage:nil
                             description:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView * padView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 24)];
    [self.view addSubview:padView];
    padView.backgroundColor = [UIColor blackColor];
    mapView.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [updateLocationTimer invalidate];
    updateLocationTimer = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CLLocation * showFromStart;
    userCoordinates = [[MWLocationFacade sharedInstance].locationManager deviceLocation];
    if (self.markedLocation)
    {
        showFromStart = self.markedLocation;
    }
    else
    {
        if (_poiArray.count)
            [self addPoiFromArray];
        
        if (!userCoordinates)
            updateLocationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                                   target:self
                                                                 selector:@selector(setUserLocation)
                                                                 userInfo:nil
                                                                  repeats:YES];
        else
            showFromStart = userCoordinates;
    }

    if (showFromStart)
        [self showMapAtZoom:0.01 andLocation:showFromStart];
}

- (void)setUserLocation
{
    userCoordinates = [[MWLocationFacade sharedInstance].locationManager deviceLocation];
    if (userCoordinates)
    {
        [self showMapAtZoom:0.01 andLocation:userCoordinates];
        [updateLocationTimer invalidate];
        updateLocationTimer = nil;
    }
}

- (void)addPoiFromArray
{
    for (NSDictionary * poiDict in _poiArray)
    {
        [self addAnnotationWithTitle:poiDict[@"t"]
                          atLatitude:[poiDict[@"lt"] doubleValue]
                        andLongitude:[poiDict[@"lg"] doubleValue]];
    }
}

- (void)addAnnotationWithTitle:(NSString *)title atLatitude:(double)latitude andLongitude:(double)longitude
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    MWMapPointAnnotation * annotation = [[MWMapPointAnnotation alloc] initWithCoordinate:coordinate];
    annotation.title = title;
    [mapView addAnnotation:annotation withIdentifier:locationSelectAnnotationViewIdentifier];
}

- (void)showMapAtZoom:(float)zoom andLocation:(CLLocation *)locationForPin
{
    MWMapCoordinateSpan * span = [[MWMapCoordinateSpan alloc] initWithLatitudeDelta:zoom longitudeDelta:zoom];
    if (mapView.region.span.latitudeDelta < zoom || mapView.region.span.longitudeDelta < zoom)
        span = mapView.region.span;

    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(locationForPin.coordinate.latitude,
            locationForPin.coordinate.longitude);
    MWMapRegion * mapRegion = [[MWMapRegion alloc] initWithCenter:location span:span];

    [mapView setRegion:mapRegion animated:YES];

    MWUniversalGeocoder * geocoder = [[MWUniversalGeocoder alloc]init];
    [geocoder reverseGeocodeLocation:locationForPin completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            for (id<MWMapAnnotation> annotation in mapView.annotations) [mapView removeAnnotation: annotation];
            id<MWGeocoderPlaceMark> placemark = [placemarks lastObject];
            [self addAnnotationWithTitle:placemark.formattedAddress andLocation:placemark.location];
        }
    }];
}

- (void)addAnnotationWithTitle:(NSString *)title andLocation:(CLLocation *)location
{
    currentCoordinates = location;
    CLLocationCoordinate2D coordinates;
    coordinates.latitude = location.coordinate.latitude;
    coordinates.longitude = location.coordinate.longitude;
    
    MWMapPointAnnotation * annotation = [[MWMapPointAnnotation alloc]initWithCoordinate:coordinates];
    annotation.title = title;
    description = title;
    [mapView addAnnotation:annotation withIdentifier:locationSelectAnnotationViewIdentifier];
}

- (UIView<MWMapAnnotationView> *)mapView:(id<MWMapView>)map
                       viewForAnnotation:(id <MWMapAnnotation>)annotation
                          withIdentifier:(NSString *)identifier
{
    if ([locationSelectAnnotationViewIdentifier isEqualToString:identifier])
    {
        CalloutMapAnnotationView * annotationView = [[CalloutMapAnnotationView alloc]init];
        annotationView.delegate = self;
        return annotationView;
    }
    else
    {
        return nil;
    }
}

-(void)mapView:(id<MWMapView>)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    MWMapPointAnnotation * annotation = [[MWMapPointAnnotation alloc]initWithCoordinate:coordinate];
    annotation.subtitle = [NSString stringWithFormat:@"Lat: %f, Long: %f", coordinate.latitude, coordinate.longitude];
    
    CLLocation * location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    [self showMapAtZoom:0.01 andLocation:location];
}

-(void)mapView:(id<MWMapView>)mapView didTapAtViewForAnnotation:(id<MWMapAnnotation>)didTapAtViewForAnnotation
{
    if (self.markedLocation) return;
    
    UIImage * imageFromMap = [PBConsoleConstants renderViewToImage:mapView];
    
    CGSize sizeOfImage = imageFromMap.size;
    
    float yPosition = (sizeOfImage.height - 100)/2;
    float xPosition = (sizeOfImage.width - 100)/2;
    
    CGRect newBounds = CGRectMake(xPosition, yPosition, 100.0, 100.0);
    
    UIImage * imageSend = [imageFromMap croppedImage:newBounds];
    
    [self.delegate showMapViewController:self
               didFinishEnteringLocation:currentCoordinates
                               withImage:imageSend
                             description:description];
}

@end
