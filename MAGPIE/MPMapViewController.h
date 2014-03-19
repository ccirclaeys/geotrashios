//
//  MPMapViewController.h
//  MAGPIE
//
//  Created by Charles Circlaeys on 15/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "MPTrashView.h"

@interface MPMapViewController : UIViewController
<MKMapViewDelegate, MPTrashViewDelegate>

@end
