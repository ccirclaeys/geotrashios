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

static CGFloat const kMetersPerMile = 1609.344;

@interface MPMapViewController ()

@property (nonatomic, strong) MKMapView *mapView;

@property (nonatomic, assign) BOOL isRouting;
@property (nonatomic, strong) NSArray *overlayRouteArray;

@property (nonatomic, strong) NSMutableDictionary *trashDictionary;

@property (nonatomic, strong) MPTrashView *currentTrashView;
@property (nonatomic, strong) MPWrapperStepsView *wrapperStepsView;

@property (nonatomic, assign) BOOL isInitialLocation;

@end

@implementation MPMapViewController

- (void)setup
{
    _trashDictionary  = [NSMutableDictionary dictionary];
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
    
    __weak MPMapViewController *weakSelf = self;
    
    [httpClient getTrashLocationsWithParams:params forSuccess:^(NSDictionary *json)
    {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        
        @autoreleasepool {
            
//            NSLog(@"json = %@", json);
            
            for (id object in json)
            {
                Trash *trash = [[Trash alloc] initWithJson:object];
                
                if (![weakSelf.trashDictionary objectForKey:trash.name])
                {
                    [weakSelf addTrashToMap:trash];
                    [weakSelf.trashDictionary setObject:trash forKey:trash.name];
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
    
    MKDirections *direction = [[MKDirections alloc]initWithRequest:request];
    
    __weak MPMapViewController *weakSelf = self;
    
    [direction calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        
        NSLog(@"response = %@",response);
        
        if (response)
        {
            _isRouting = YES;
            
            NSArray *arrRoutes = [response routes];
            
            NSMutableArray *overlayRouteArray = [NSMutableArray arrayWithCapacity:arrRoutes.count];
            
            [arrRoutes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                MKRoute *rout = obj;
                
                MKPolyline *line = [rout polyline];
                [weakSelf.mapView addOverlay:line];
                [overlayRouteArray addObject:line];
                
                NSLog(@"Rout Name : %@",rout.name);
                NSLog(@"Total Distance (in Meters) :%f",rout.distance);
                
                NSArray *steps = [rout steps];
                
                NSLog(@"Total Steps : %ld",(unsigned long)[steps count]);
                
                [steps enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSLog(@"Rout Instruction : %@",[obj instructions]);
                    NSLog(@"Rout Distance : %f",[obj distance]);
                }];
                
                MPWrapperStepsView *wrapperStepsView = [[MPWrapperStepsView alloc] initWithNib];
                wrapperStepsView.frame = CGRectMake(0, weakSelf.view.bounds.size.height - wrapperStepsView.frame.size.height, wrapperStepsView.frame.size.width, wrapperStepsView.frame.size.height);
                [wrapperStepsView setupWithSteps:steps];
                [weakSelf.view addSubview:wrapperStepsView];
                
                weakSelf.wrapperStepsView = wrapperStepsView;
                
            }];
            
            weakSelf.overlayRouteArray = overlayRouteArray;
            
            [weakSelf addCancelButton];
            
            [_mapView setCenterCoordinate:_mapView.userLocation.location.coordinate zoomLevel:20 animated:YES];
            
            
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Direction" message:@"No route found" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alertView show];
        }
    }];
    
    [_mapView deselectAnnotation:trashView.annotationView.annotation animated:NO];
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
