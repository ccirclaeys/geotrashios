//
//  MPWebAPIClient.h
//  MAGPIE
//
//  Created by Charles Circlaeys on 13/11/2013.
//  Copyright (c) 2013 Keley live. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCHTTPAPIClient.h"

@interface MPWebAPIClient : CCHTTPAPIClient

+ (MPWebAPIClient*)sharedClient;

+ (NSString *)getURLForSlug:(NSString*)slug;
- (void)getTrashLocationsWithParams:(NSDictionary*)dict forSuccess:(void (^)(NSDictionary *json))successBlock forFailure:(void (^)(NSError *error))failureBlock;

@end
