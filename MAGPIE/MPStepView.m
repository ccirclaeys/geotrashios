//
//  MPStepView.m
//  MAGPIE
//
//  Created by Charles Circlaeys on 21/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import "MPStepView.h"

@implementation MPStepView

- (void)setup
{
    _stepLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _stepLabel.textAlignment = NSTextAlignmentCenter;
    _stepLabel.numberOfLines = 0;
    _stepLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _stepLabel.font = [UIFont fontWithName:@"Helvetica" size:(15.0)];
    [self addSubview:_stepLabel];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.delegate didSelectStepView:self];
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
