//
//  MPWrapperStepsView.h
//  MAGPIE
//
//  Created by Charles Circlaeys on 21/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPStepView.h"

@interface MPWrapperStepsView : UIView

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

- (id)initWithNib;
- (void)setupWithSteps:(NSArray*)steps delegate:(id<MPStepViewDelegate>)delegate;

@end
