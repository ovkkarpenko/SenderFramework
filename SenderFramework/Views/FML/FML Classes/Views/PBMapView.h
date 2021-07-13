//
//  PBMapView.h
//  SENDER
//
//  Created by Eugene Gilko on 04.05.15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"
#import "ShowMapViewController.h"

@class PBMapView;

@protocol PBMapViewDelegate <PBSubviewDelegate>

- (void)getLocationForMapView:(PBMapView *)mapView withPOIs:(NSArray *)poiList;

@end

@interface PBMapView : PBSubviewFacade <ShowMapViewControllerDelegate>

@property (nonatomic, weak) id<PBMapViewDelegate> delegate;

@property (nonatomic, strong) UITextField * inputTextField;
@property (nonatomic, weak) MainContainerModel * viewModel;

- (void)setLocation:(CLLocation *)location withDescription:(NSString *)description;

@end
