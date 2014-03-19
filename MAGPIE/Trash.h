//
//  Trash.h
//  MAGPIE
//
//  Created by Charles Circlaeys on 15/03/2014.
//  Copyright (c) 2014 Charles Circlaeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Trash : NSObject

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *updatedDate;

@property (nonatomic, strong) NSNumber *longitude;
@property (nonatomic, strong) NSNumber *latitude;

- (instancetype)initWithJson:(NSDictionary*)json;

@end
