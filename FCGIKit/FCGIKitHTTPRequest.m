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

    NSArray* tokens = [queryString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    NSMutableArray* keys = [NSMutableArray array];
    NSMutableArray* objects = [NSMutableArray array];
    
    [tokens enumerateObjectsUsingBlock:^(id token, NSUInteger idx, BOOL *stop) {
        NSArray* pair = [token componentsSeparatedByString:@"="];
        NSString* key = [pair objectAtIndex:0];
        NSError *error;
        
        // test if the string is an array
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(.+)" options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray* matches = [regex matchesInString:key options:0 range:NSMakeRange(0, key.length)];
        NSLog(@"%@", key);
        if ( error ) {
            [[FCGIApplication sharedApplication] presentError:error];
        } else {
            NSLog(@"%@", matches);
        }
    }];
    
    NSMutableDictionary* vars = [NSMutableDictionary dictionary];
    return [NSDictionary dictionaryWithDictionary:vars];
}

@end

@implementation FCGIKitHTTPRequest

@synthesize FCGIRequest = _FCGIRequest;

- (id)initWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    self = [self init];
    if ( self != nil ) {

        _FCGIRequest = anFCGIRequest;
        
        body = _FCGIRequest.stdinData;
        
        _server = [NSDictionary dictionaryWithDictionary:_FCGIRequest.parameters];
        
        if ( [_server.allKeys containsObject:@"QUERY_STRING"] ) {
            _get = [self parseQueryString:[_server objectForKey:@"QUERY_STRING"]];
        } else {
            _get = [NSDictionary dictionary];
        }
        
        if ( [[_server objectForKey:@"REQUEST_METHOD"] isEqualToString:@"POST"] && [[_server objectForKey:@"CONTENT_TYPE"] isEqualToString:@"application/x-www-form-urlencoded"] ) {
            _post = [self parseQueryString:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]];
        } else if([[_server objectForKey:@"REQUEST_METHOD"] isEqualToString:@"POST"] && [[_server objectForKey:@"CONTENT_TYPE"] isEqualToString:@"multipart/form-data"]) {
            _post = [NSDictionary dictionary];
        } else {
            _post = [NSDictionary dictionary];
        }
        
        
    }
    return self;
}

+ (id)requestWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
    return [[FCGIKitHTTPRequest alloc] initWithFCGIRequest:anFCGIRequest];
}

- (NSDictionary *)serverFields
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
