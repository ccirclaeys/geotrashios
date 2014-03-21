//
//  MPWrapperStepsView.m
//  MAGPIE
//
//  Created by Charles Circlaeys on 21/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "MPWrapperStepsView.h"

@implementation MPWrapperStepsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithNib
{
    NSString *className = NSStringFromClass([self class]);
    self = [[[NSBundle mainBundle] loadNibNamed:className owner:self options:nil] objectAtIndex:0];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.userInteractionEnabled = YES;
    _scrollView.userInteractionEnabled = YES;
    
    [self setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5]];
}

- (void)setupWithSteps:(NSArray*)steps delegate:(id<MPStepViewDelegate>)delegate
{
    _scrollView.contentSize = CGSizeMake(steps.count * _scrollView.frame.size.width, _scrollView.frame.size.height);
    __block CGFloat offsetX = 0;
    
    [steps enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
       
        MPStepView *stepView = [[MPStepView alloc] initWithFrame:CGRectMake(offsetX, 0, _scrollView.frame.size.width, _scrollView.frame.size.height)];
        stepView.routeStep = obj;
        stepView.delegate = delegate;
        stepView.stepLabel.text = [obj instructions];
        [_scrollView addSubview:stepView];
        
        offsetX += _scrollView.frame.size.width;
        
    }];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
