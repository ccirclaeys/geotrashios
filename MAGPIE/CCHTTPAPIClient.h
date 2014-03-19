//
//  CCHTTPAPIClient.h
//  Ligne en Ligne
//
//  Created by Charles Circlaeys on 13/11/2013.
//  Copyright (c) 2013 Keley live. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCHTTPAPIClient : NSObject
{
    NSURL *_baseUrl;
}

@property (nonatomic, strong) NSURL *baseUrl;

- (id)initWithBaseURL:(NSURL*)baseUrl;
- (BOOL)isInternetConnection;

- (void)requestMethod:(NSString*)method forPath:(NSString*)path forSuccess:(void (^)(NSDictionary *json))successBlock forFailure:(void (^)(NSError *error))failureBlock withParams:(id)params;
//- (NSString*)decodeFromPercentEscapeString:(NSString *)string;

@end
