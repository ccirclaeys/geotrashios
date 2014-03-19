//
//  MPMapViewController.m
//  MAGPIE
//
//  Created by Charles Circlaeys on 15/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import "MPMapViewController.h"
#import "MPWebAPIClient.h"
#import "Trash.h"

static CGFloat const kMetersPerMile = 1609.344;

@interface MPMapViewController ()

@property (nonatomic, strong) MKMapView *mapView;

@property (nonatomic, assign) BOOL isRouting;
@property (nonatomic, strong) NSArray *overlayRouteArray;

@property (nonatomic, strong) NSArray *trashArray;
@property (nonatomic, strong) NSMutableDictionary *trashDictionary;

@property (nonatomic, strong) MPTrashView *currentTrashView;

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
    
    _mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode = YES;
    
    [self requestNearTrashLocations];
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - API request

- (void)requestNearTrashLocations
{
    MPWebAPIClient *httpClient = [MPWebAPIClient sharedClient];
    
    [httpClient getTrashLocationsWithParams:nil forSuccess:^(NSDictionary *json)
    {
        
        @autoreleasepool {
            
//            NSLog(@"json = %@", json);
            
            NSMutableArray *trashArray = [NSMutableArray array];
            for (id object in json)
            {
                Trash *trash = [[Trash alloc] initWithJson:object];
                [self addTrashToMap:trash];
                [trashArray addObject:trash];
            }
            
            self.trashArray = trashArray;
        }
        
    } forFailure:^(NSError *error) {
        
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
    
    [_trashDictionary setObject:trash forKey:point.title];
}

- (void)cancelRoute
{
    _isRouting = NO;
    
    [_mapView removeOverlays:_overlayRouteArray];
    self.navigationItem.leftBarButtonItem = nil;
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

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation NS_AVAILABLE(10_9, 4_0)
{
    NSLog(@"didUpdateUserLocation");

//    [self requestNearTrashLocations];
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
    
    [direction calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        
        NSLog(@"response = %@",response);
        
        _isRouting = YES;

        NSArray *arrRoutes = [response routes];
        
        NSMutableArray *overlayRouteArray = [NSMutableArray arrayWithCapacity:arrRoutes.count];
        
        [arrRoutes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            MKRoute *rout = obj;
            
            MKPolyline *line = [rout polyline];
            [_mapView addOverlay:line];
            [overlayRouteArray addObject:line];
            
            NSLog(@"Rout Name : %@",rout.name);
            NSLog(@"Total Distance (in Meters) :%f",rout.distance);
            
            NSArray *steps = [rout steps];
            
            NSLog(@"Total Steps : %d",[steps count]);
            
            [steps enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSLog(@"Rout Instruction : %@",[obj instructions]);
                NSLog(@"Rout Distance : %f",[obj distance]);
            }];
        }];
        
        _overlayRouteArray = overlayRouteArray;
        
        [self addCancelButton];

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

- (void)addCancelButton
{
    UIBarButtonItem *customBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelRoute)];
    self.navigationItem.leftBarButtonItem = customBarButton;
}

@end
