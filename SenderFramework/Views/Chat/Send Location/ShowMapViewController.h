//
//  ShowMapViewController.h
//  SENDER
//
//  Created by Eugene on 11/21/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "CalloutMapAnnotationView.h"

@class ShowMapViewController;

@protocol ShowMapViewControllerDelegate <NSObject>

- (void)showMapViewController:(ShowMapViewController *)controller
    didFinishEnteringLocation:(CLLocation *)location
                    withImage:(UIImage *)image
                  description:(NSString *)description;

@end

@protocol MWMapViewDelegate;

@interface ShowMapViewController : UIViewController <CLLocationManagerDelegate,
                                                     MWMapViewDelegate,
                                                     CalloutMapAnnotationViewDelegate>

@property (nonatomic, assign) id<ShowMapViewControllerDelegate> delegate;
@property (nonatomic, strong) CLLocation * markedLocation;
@property (nonatomic, strong) NSArray * poiArray;

@end
