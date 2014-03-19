//
//  MPTrashView.m
//  MAGPIE
//
//  Created by Charles Circlaeys on 18/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import "MPTrashView.h"
#import "Trash.h"

@implementation MPTrashView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithNib
{
    NSString *className = NSStringFromClass([self class]);
    self = [[[NSBundle mainBundle] loadNibNamed:className owner:self options:nil] objectAtIndex:0];
    if (self)
    {
        //[self setup];
    }
    return self;
}

- (void)setupWithTrash:(Trash *)trash
{
    _trash = trash;
    
    _titleLabel.text = trash.name;
    _descriptionLabel.text = trash.description;
    
    [_titleLabel sizeToFit];
    [_descriptionLabel sizeToFit];
}

- (IBAction)goButton:(id)sender
{
    MKDirectionsTransportType type = MKDirectionsTransportTypeAutomobile;
    
    if (_transportSegmentedControl.selectedSegmentIndex != 0)
        type = MKDirectionsTransportTypeWalking;
    
    [self.delegate trashViewDidStart:self forTransportType:type];
}

- (IBAction)cancelButton:(id)sender
{
    [self.delegate trashViewDidCancel:self];
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
