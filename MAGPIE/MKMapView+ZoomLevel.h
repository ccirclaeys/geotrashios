//
//  MKMapView+ZoomLevel.h
//  MAGPIE
//
//  Created by Charles Circlaeys on 20/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (ZoomLevel)
- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;

-(double) getZoomLevel;
@end

