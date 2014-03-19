//
//  Trash.m
//  MAGPIE
//
//  Created by Charles Circlaeys on 15/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import "Trash.h"

@implementation Trash

- (instancetype)initWithJson:(NSDictionary*)json
{
    if (self = [super init])
    {
        NSArray *loc = nil;

        SET_IF_NOT_NULL(self.identifier, [json valueForKey:@"_id"]);
        SET_IF_NOT_NULL(self.name, [json valueForKey:@"name"]);
        SET_IF_NOT_NULL(self.description, [json valueForKey:@"description"]);
        SET_IF_NOT_NULL(self.updatedDate, [json valueForKey:@"postedOn"]);
        SET_IF_NOT_NULL(loc, [json valueForKey:@"loc"]);

        if (loc.count == 2)
        {
            self.longitude = [loc firstObject];
            self.latitude = [loc lastObject];
        }
    }
    return self;
}

@end
