//
//  MPWebAPIClient.m
//  MAGPIE
//
//  Created by Charles Circlaeys on 13/11/2013.
//  Copyright (c) 2013 Keley live. All rights reserved.
//

#import "MPWebAPIClient.h"

static NSString * const kMPAPIBaseURLDevString = @"http://geotrashapi-ccirclaeys.rhcloud.com";
static NSString * const kGetTrashLocations = @"/trash/near";

@implementation MPWebAPIClient

+ (MPWebAPIClient*)sharedClient
{
    static MPWebAPIClient *sharedClient = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[super allocWithZone:nil] initWithBaseURL:[NSURL URLWithString:kMPAPIBaseURLDevString]];
    });
    return sharedClient;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedClient];
}

+ (NSString *)getURLForSlug:(NSString*)slug
{
    return [NSString stringWithFormat:@"%@%@", kMPAPIBaseURLDevString, slug];
}

- (void)getTrashLocationsWithParams:(NSDictionary*)dict forSuccess:(void (^)(NSDictionary *json))successBlock forFailure:(void (^)(NSError *error))failureBlock
{
    [self requestMethod:@"GET" forPath:kGetTrashLocations forSuccess:^(NSDictionary *json) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            successBlock(json);
        });
        
    } forFailure:^(NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            failureBlock(error);
        });
        
    } withParams:dict];
}


@end
