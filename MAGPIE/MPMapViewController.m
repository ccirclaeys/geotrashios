//
//  MPMapViewController.m
//  MAGPIE
//
//  Created by Charles Circlaeys on 15/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import "MPMapViewController.h"
#import "MKMapView+ZoomLevel.h"
#import "MPWebAPIClient.h"
#import "Trash.h"
#import "AppDelegate.h"
#import "MPSettingsViewController.h"
#import "MPWrapperStepsView.h"
#import "objc/runtime.h"

static CGFloat const kMetersPerMile = 1609.344;

static void *MPMapViewControllerAlertDestinationKey = "MPMapViewControllerAlertDestinationKey";

@interface MPMapViewController ()

@property (nonatomic, strong) MKMapView *mapView;

@property (nonatomic, assign) BOOL isRouting;
@property (nonatomic, strong) NSMutableArray *overlayRouteArray;

@property (nonatomic, strong) NSMutableDictionary *trashDictionary;

@property (nonatomic, strong) MPTrashView *currentTrashView;
@property (nonatomic, strong) MPWrapperStepsView *wrapperStepsView;
@property (nonatomic, assign) CLLocationCoordinate2D destinationCoordinate;

@property (nonatomic, assign) BOOL isInitialLocation;

@end

@implementation MPMapViewController

- (void)setup
{
    _trashDictionary  = [NSMutableDictionary dictionary];
    _overlayRouteArray = [NSMutableArray array];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        [self setup];

    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupNavigationBar];
    
    _mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    
    _mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
    _mapView.showsUserLocation = YES;
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [_trashDictionary removeAllObjects];
    // Dispose of any resources that can be recreated.
}

#pragma mark - API request

- (void)requestNearTrashLocations
{
    MKMapRect mRect = _mapView.visibleMapRect;
    MKMapPoint eastMapPoint = MKMapPointMake(MKMapRectGetMinX(mRect), MKMapRectGetMidY(mRect));
    MKMapPoint westMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), MKMapRectGetMidY(mRect));
    
    CLLocationDistance distance = MKMetersBetweenMapPoints(eastMapPoint, westMapPoint);
    
    CLLocationCoordinate2D centerLocation = _mapView.centerCoordinate;

    NSDictionary *params = @{@"longitude": [NSString stringWithFormat:@"%f", centerLocation.longitude],
                             @"latitude": [NSString stringWithFormat:@"%f", centerLocation.latitude],
                             @"distance": [NSString stringWithFormat:@"%f", distance]};
    
    MPWebAPIClient *httpClient = [MPWebAPIClient sharedClient];
    
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    
    [httpClient getTrashLocationsWithParams:params forSuccess:^(NSDictionary *json)
    {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        @autoreleasepool {
            
//            NSLog(@"json = %@", json);
            
            for (id object in json)
            {
                Trash *trash = [[Trash alloc] initWithJson:object];
                
                if (![_trashDictionary objectForKey:trash.name])
                {
                    [self addTrashToMap:trash];
                    [_trashDictionary setObject:trash forKey:trash.name];
                }
            }
        }
        
    } forFailure:^(NSError *error) {
        
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];

        NSLog(@"error = %@", error);
    }];
}

#pragma mark - Map methods

- (void)addTrashToMap:(Trash *)trash
{
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = trash.latitude.floatValue;
    coordinate.longitude = trash.longitude.floatValue;
    point.coordinate = coordinate;
    point.title = trash.name;
    [_mapView addAnnotation:point];
}

- (void)cancelRoute
{
    _isRouting = NO;
    
    [_mapView removeOverlays:_overlayRouteArray];
    self.navigationItem.leftBarButtonItem = nil;
    
    [_wrapperStepsView removeFromSuperview];
    _wrapperStepsView = nil;
    
    [_mapView setCenterCoordinate:_mapView.userLocation.location.coordinate zoomLevel:12 animated:YES];
}

#pragma  mark - MKMapView delegate

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) annotation
{
    MKPinAnnotationView *pinView = nil;
    
    if (annotation != self.mapView.userLocation)
    {
        static NSString *defaultPinID = @"defaultPinID";
        pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:defaultPinID];
        if (pinView == nil)
        {
            pinView = [[MKPinAnnotationView alloc]
                       initWithAnnotation:annotation reuseIdentifier:defaultPinID];
        }
        
        pinView.canShowCallout = NO;

    }
    
    return pinView;
}

- (void)centerMapAtLatitude:(float)latitude andLongitude:(float)longitude
{
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = latitude;
    zoomLocation.longitude = longitude;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 15 * kMetersPerMile, 15 * kMetersPerMile);
    [_mapView setRegion:viewRegion animated:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if ( !_isInitialLocation && userLocation.location)
    {
        _isInitialLocation = YES;
        [_mapView setCenterCoordinate:userLocation.location.coordinate zoomLevel:12 animated:YES];
    }
    else
    {
        if (_isRouting)
        {
            CLLocation *locA = [[CLLocation alloc] initWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
            CLLocation *locB = [[CLLocation alloc] initWithLatitude:_destinationCoordinate.latitude longitude:_destinationCoordinate.longitude];
            
            CLLocationDistance distance = ([locA distanceFromLocation:locB]) / 1000;
            
            if (distance <= 0.02f)
            {
                _isRouting = NO;
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Arrived" message:@"You arrived at the destination!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                
                void (^block)(NSInteger) = ^(NSInteger buttonIndex) {
                    [self cancelRoute];
                };
                
                objc_setAssociatedObject(alertView,
                                         MPMapViewControllerAlertDestinationKey,
                                         block,
                                         OBJC_ASSOCIATION_COPY);
                
                [alertView show];

            }
        }
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view NS_AVAILABLE(10_9, 4_0)
{
    if (_isRouting)
    {
        [_mapView deselectAnnotation:view.annotation animated:NO];
        return;
    }
    
    MKPointAnnotation *point = (MKPointAnnotation*)view.annotation;
    Trash *currentTrash = [_trashDictionary objectForKey:point.title];
    
    if (currentTrash)
    {
        [_currentTrashView removeFromSuperview];
        
        _currentTrashView = [[MPTrashView alloc] initWithNib];
        _currentTrashView.delegate = self;
        _currentTrashView.annotationView = view;
        [_currentTrashView setupWithTrash:currentTrash];
        _currentTrashView.center = self.view.center;
        [self.view addSubview:_currentTrashView];

        [[_currentTrashView layer] addAnimation:[self animationScaleUp] forKey:@"scaleUp"];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view NS_AVAILABLE(10_9, 4_0)
{
    [[_currentTrashView layer] addAnimation:[self animationScaleDown] forKey:@"scaleDown"];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay {
    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView* aView = [[MKPolylineView alloc]initWithPolyline:(MKPolyline*)overlay] ;
        aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
        aView.lineWidth = 10;
        return aView;
    }
    return nil;
}

//- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
//{
//    if ([overlay isKindOfClass:[MKPolyline class]]) {
//    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
//    renderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
//    renderer.lineWidth = 4.f;
//    return  renderer;
//    }
//    return nil;
//}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self requestNearTrashLocations];
}

#pragma mark - MPTrashViewDelegate

- (void)trashViewDidCancel:(MPTrashView*)trashView
{
    [[_currentTrashView layer] addAnimation:[self animationScaleDown] forKey:@"scaleDown"];
    
    [_mapView deselectAnnotation:trashView.annotationView.annotation animated:NO];
}

- (void)trashViewDidStart:(MPTrashView*)trashView forTransportType:(MKDirectionsTransportType)transportType
{
    Trash *currentTrash = trashView.trash;
    
    [[_currentTrashView layer] addAnimation:[self animationScaleDown] forKey:@"scaleDown"];
    
    MKPlacemark *destination = [[MKPlacemark alloc]initWithCoordinate:CLLocationCoordinate2DMake(currentTrash.latitude.floatValue, currentTrash.longitude.floatValue) addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"", nil] ];
    
    MKMapItem *distMapItem = [[MKMapItem alloc]initWithPlacemark:destination];
    [distMapItem setName:@""];
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc]init];
    request.source =  [MKMapItem mapItemForCurrentLocation];
    [request setDestination:distMapItem];
    [request setTransportType:transportType];
    
    request.requestsAlternateRoutes = NO;
    
    MKDirections *direction = [[MKDirections alloc] initWithRequest:request];
    
    [direction calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        
        if (response)
        {
            
            @autoreleasepool {
                
                _isRouting = YES;
                
                NSArray *arrRoutes = [response routes];
                
                [arrRoutes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    
                    MKRoute *rout = obj;
                    
                    MKPolyline *line = [rout polyline];
                    [_mapView addOverlay:line];
                    [_overlayRouteArray addObject:line];
                    
                    NSLog(@"Rout Name : %@",rout.name);
                    NSLog(@"Total Distance (in Meters) :%f",rout.distance);
                    
                    NSArray *steps = [rout steps];
                    
                    NSLog(@"Total Steps : %ld",(unsigned long)[steps count]);
                    
                    [steps enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSLog(@"Rout Instruction : %@",[obj instructions]);
                        NSLog(@"Rout Distance : %f",[obj distance]);
                    }];
                    
                    MPWrapperStepsView *wrapperStepsView = [[MPWrapperStepsView alloc] initWithNib];
                    wrapperStepsView.frame = CGRectMake(0, self.view.bounds.size.height - wrapperStepsView.frame.size.height, wrapperStepsView.frame.size.width, wrapperStepsView.frame.size.height);
                    [wrapperStepsView setupWithSteps:steps delegate:self];
                    [self.view addSubview:wrapperStepsView];
                    
                    _wrapperStepsView = wrapperStepsView;
                    _destinationCoordinate = ((MKRouteStep*)[steps lastObject]).polyline.coordinate;
                    
                }];
                
                [self addCancelButton];
                [_mapView setCenterCoordinate:_mapView.userLocation.location.coordinate zoomLevel:20 animated:YES];
            }
            
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Direction" message:@"No route found" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alertView show];
        }
    }];
    
    [_mapView deselectAnnotation:trashView.annotationView.annotation animated:NO];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    void (^block)(NSInteger) = objc_getAssociatedObject(alertView, MPMapViewControllerAlertDestinationKey);
    block(buttonIndex);
}

#pragma mark - Animations

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)isFinished
{
    if (isFinished)
    {
        CABasicAnimation *animation = (CABasicAnimation*)anim;
        
        if ([[animation valueForKey:@"animationType"] isEqualToString:@"scaleDown"])
        {
            [_currentTrashView removeFromSuperview];
            _currentTrashView = nil;
        }
    }
}

- (CABasicAnimation*)animationScaleUp
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [animation setFromValue:[NSNumber numberWithFloat:0]];
    [animation setToValue:[NSNumber numberWithFloat:1]];
    [animation setDuration:0.1f];
    animation.delegate = self;
    [animation setRemovedOnCompletion:NO];
    [animation setFillMode:kCAFillModeForwards];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.34 :.01 :.69 :1.37]];
    [animation setValue:@"scaleUp" forKey:@"animationType"];
    return animation;
}

- (CABasicAnimation*)animationScaleDown
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [animation setFromValue:[NSNumber numberWithFloat:1]];
    [animation setToValue:[NSNumber numberWithFloat:0]];
    [animation setDuration:0.1f];
    animation.delegate = self;
    [animation setRemovedOnCompletion:NO];
    [animation setFillMode:kCAFillModeForwards];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.34 :.01 :.69 :1.37]];
    [animation setValue:@"scaleDown" forKey:@"animationType"];
    return animation;
}

#pragma mark - MPWrapperStepsView delegate

- (void)didSelectStepView:(MPStepView*)stepView;
{
    if (MKMapRectIsEmpty(stepView.routeStep.polyline.boundingMapRect))
    {
        [_mapView setRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake(stepView.routeStep.polyline.coordinate.latitude, stepView.routeStep.polyline.coordinate.longitude), _mapView.region.span) animated:YES];
        return;
    }
    
    [_mapView addOverlay:stepView.routeStep.polyline];
    [_mapView setVisibleMapRect:stepView.routeStep.polyline.boundingMapRect animated:YES];
    
    [_overlayRouteArray addObject:stepView.routeStep.polyline];
}

#pragma mark - navigation controller

- (void)setupNavigationBar
{
    UIBarButtonItem *settingsBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(goToSettingsView)];
    self.navigationItem.rightBarButtonItem = settingsBarButton;
}

- (void)addCancelButton
{
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelRoute)];
    self.navigationItem.leftBarButtonItem = cancelBarButton;
}

#pragma mark - transition controllers

- (void)goToSettingsView
{
    MPSettingsViewController *settingsViewController = [[MPSettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

@end
