//
//  FCGIKitHTTPRequest.m
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitHTTPRequest.h"
#import "FCGIRequest.h"

@interface FCGIKitHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString;

@end

@implementation FCGIKitHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString
{
    NSMutableDictionary* get = [NSMutableDictionary dictionary];
    return [NSDictionary dictionaryWithDictionary:get];
}

@end

@implementation FCGIKitHTTPRequest

@synthesize FCGIRequest = _FCGIRequest;

- (id)initWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
    self = [self init];
    if ( self != nil ) {
        _FCGIRequest = anFCGIRequest;
        _server = [NSDictionary dictionaryWithDictionary:_FCGIRequest.parameters];
        _get = [self parseQueryString:[_server  objectForKey:@"QUERY_STRING"]];
    }
    return self;
}

+ (id)requestWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
    return [[FCGIKitHTTPRequest alloc] initWithFCGIRequest:anFCGIRequest];
}

- (NSDictionary *)serverFitelds
{
    return _server;
}

- (NSDictionary *)getFields
{
    return _get;
}

- (NSDictionary *)cookieFields
{
    return _cookie;
}

- (NSDictionary *)postFields
{
    return _post;
}

@end
