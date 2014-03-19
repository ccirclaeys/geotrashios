//
//  CCHTTPAPIClient.m
//  Ligne en Ligne
//
//  Created by Charles Circlaeys on 13/11/2013.
//  Copyright (c) 2013 Keley live. All rights reserved.
//

#import "CCHTTPAPIClient.h"
#import "Reachability.h"

@implementation CCHTTPAPIClient
{
    NSURLSession *_currentSession;
}

- (id)initWithBaseURL:(NSURL*)baseUrl
{
    if (self = [super init])
    {
        self.baseUrl = baseUrl;
    }
    return self;
}

- (BOOL)isInternetConnection
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable)
        return NO;
    return YES;
}

- (NSData *)URLEncoder:(NSDictionary*)dictionary
{
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    for (NSString *key in dictionary)
    {
        NSString *encodedValue = [[dictionary objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject:part];
    }
    NSString *encodedDictionary = [parts componentsJoinedByString:@"&"];
    return [encodedDictionary dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSURL*)getUrlForPath:(NSString*)path
{
    return [NSURL URLWithString:path relativeToURL:_baseUrl];
}

- (void)requestMethod:(NSString*)method forPath:(NSString*)path forSuccess:(void (^)(NSDictionary *json))successBlock forFailure:(void (^)(NSError *error))failureBlock withParams:(id)params
{
    NSURLSessionTask *task = nil;
    
    [_currentSession finishTasksAndInvalidate];
    
    if ([method isEqualToString:@"GET"])
    {
        if (params)
        {
            NSString *dataString = [[NSString alloc] initWithData:[self URLEncoder:params] encoding:NSUTF8StringEncoding];
            path = [[path stringByAppendingString:@"?"] stringByAppendingString:dataString];
        }

//        NSLog(@"Path = %@", path);
        task = [self GETRequestForPath:path successCompletionBlock:successBlock failure:failureBlock];
    }
    else
    {
        task = [self request:method forPath:path withParams:params successCompletionBlock:successBlock failure:failureBlock];
    }
    
    [task resume];
}

- (NSURLSessionTask*)GETRequestForPath:(NSString*)path successCompletionBlock:(void (^)(NSDictionary *json))success failure:(void (^)(NSError *error))failure
{
    NSString *authToken = nil;
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    if (authToken)
        [config setHTTPAdditionalHeaders:@{@"Cookie":[NSString stringWithFormat:@"auth_token=%@", authToken]}];
    
    _currentSession = [NSURLSession sessionWithConfiguration:config];
    
    return [_currentSession dataTaskWithURL:[self getUrlForPath:path]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                if (error)
                    failure(error);
                else
                {
                    NSError *jsonError;
                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                    
                    if (jsonError)
                        failure(jsonError);
                    else
                        success(dict);
                }
                
            }];
}

- (NSURLSessionTask*)request:(NSString*)requestType forPath:(NSString*)path withParams:(NSDictionary*)paramsDict successCompletionBlock:(void (^)(NSDictionary *json))success failure:(void (^)(NSError *error))failure
{
    _currentSession = [NSURLSession sharedSession];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self getUrlForPath:path]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSString *authToken = nil;
    
    if (authToken)
        [request addValue:[NSString stringWithFormat:@"auth_token=%@", authToken] forHTTPHeaderField:@"Cookie"];
    
    [request setHTTPMethod:requestType];
    NSError *error;
    
    NSData *postData = nil;
    if (paramsDict)
        postData = [NSJSONSerialization dataWithJSONObject:paramsDict options:0 error:&error];
    
    [request setHTTPBody:postData];
    
    return [_currentSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
      //  NSLog(@"Status code = %ld", (long)[httpResp statusCode]);
        
        NSError *jsonError;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if ([requestType isEqualToString:@"POST"] && jsonError)
        {
            failure(error);
            return;
        }

        if (httpResp.statusCode == 200)
            success(dict);
        else
        {
            failure(error);
        }
        
    }];

}

/* Leak

- (NSString*) decodeFromPercentEscapeString:(NSString *) string {
    return (__bridge NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                         (__bridge CFStringRef) string,
                                                                                         CFSTR(""),
                                                                                         kCFStringEncodingUTF8);
}
 
 */

@end
