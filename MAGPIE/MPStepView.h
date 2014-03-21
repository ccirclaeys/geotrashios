//
//  MPStepView.h
//  MAGPIE
//
//  Created by Charles Circlaeys on 21/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MPStepView;
@class MKRouteStep;

@protocol MPStepViewDelegate <NSObject>

- (void)didSelectStepView:(MPStepView*)stepView;

@end

@interface MPStepView : UIView

@property (nonatomic, strong) MKRouteStep *routeStep;

@property (nonatomic, strong) UILabel *stepLabel;
@property (nonatomic, weak) id <MPStepViewDelegate> delegate;

@end
