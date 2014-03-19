//
//  MPTrashView.h
//  MAGPIE
//
//  Created by Charles Circlaeys on 18/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MKDirectionsTypes.h>

@class Trash;
@class MPTrashView;
@class MKAnnotationView;

@protocol MPTrashViewDelegate <NSObject>

- (void)trashViewDidCancel:(MPTrashView*)trashView;
- (void)trashViewDidStart:(MPTrashView*)trashView forTransportType:(MKDirectionsTransportType)transportType;

@end

@interface MPTrashView : UIView

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;

@property (nonatomic, weak) IBOutlet UISegmentedControl *transportSegmentedControl;

@property (nonatomic, weak) IBOutlet UIButton *goButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@property (nonatomic, strong) MKAnnotationView *annotationView;
@property (nonatomic, strong) Trash *trash;

@property (nonatomic, weak) id <MPTrashViewDelegate> delegate;

- (id)initWithNib;
- (void)setupWithTrash:(Trash*)trash;

- (IBAction)goButton:(id)sender;
- (IBAction)cancelButton:(id)sender;

@end
