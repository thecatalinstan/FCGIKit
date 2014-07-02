//
//  FCGIKitHTTPResponse.m
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FKHTTPResponse.h"
#import "FKApplication.h"
#import "FKHTTPRequest.h"
#import "NSString+FCGIKit.h"
#import "NSHTTPCookie+FCGIKit.h"

@interface FKHTTPResponse(Private)

- (void)sendHTTPStatus;
- (NSString*)buildHTTPHeaders;
- (void)sendHTTPHeaders;

@end

@implementation FKHTTPResponse(Private)

- (void)sendHTTPStatus
{
    if ( _headersAlreadySent ) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"HTTP headers have already been sent." userInfo:HTTPHeaders.copy];
        return;
    }

    NSData* data = [[NSString stringWithFormat:@"Status: %lu\n", (unsigned long)self.HTTPStatus] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* userInfo = @{FKRequestKey: self.HTTPRequest.FCGIRequest, FKDataKey: data == nil ? [NSData data] : data };
    [[FKApplication sharedApplication] writeDataToStdout:userInfo];
}

- (NSString *)buildHTTPHeaders
{
    // Add the cookie headers
    NSDictionary * cookieHeaders = [NSHTTPCookie responseHeaderFieldsWithCookies:HTTPCookies.allValues];
    [self setAllHTTPHeaderFields:cookieHeaders];
        
    // Compile all the headers
    __block NSMutableArray* compiledHeaders = [[NSMutableArray alloc] initWithCapacity:HTTPHeaders.count];
    [HTTPHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [compiledHeaders addObject:[NSString stringWithFormat:@"%@: %@", key, obj]];
    }];
    return [compiledHeaders componentsJoinedByString:@"\r\n"];
}

- (void)sendHTTPHeaders
{
    [self sendHTTPStatus];
    
    NSData* data = [[self.buildHTTPHeaders stringByAppendingString:@"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* userInfo = @{FKRequestKey: self.HTTPRequest.FCGIRequest, FKDataKey: data == nil ? [NSData data] : data };
    [[FKApplication sharedApplication] writeDataToStdout:userInfo];

    _headersAlreadySent = YES;
}

@end

@implementation FKHTTPResponse

@synthesize HTTPRequest = _HTTPRequest;
@synthesize headersAlreadySent = _headersAlreadySent;
@synthesize HTTPStatus = _HTTPStatus;
@synthesize isRedirecting = _isRedirecting;

- (id)initWithHTTPRequest:(FKHTTPRequest *)anHTTPRequest
{
    self = [self init];
    if ( self != nil ) {
        _HTTPRequest = anHTTPRequest;
        _HTTPStatus = 200;
        HTTPHeaders = [[NSMutableDictionary alloc] init];
        HTTPCookies = [[NSMutableDictionary alloc] init];
        _headersAlreadySent = NO;
    }
    return self;
}

+ (id)responseWithHTTPRequest:(FKHTTPRequest *)anHTTPRequest
{
    return [[FKHTTPResponse alloc] initWithHTTPRequest:anHTTPRequest];
}

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    id obj = [HTTPHeaders objectForKey:field];
    if ([obj isKindOfClass:[NSString class]] ) {
        value = [value stringByAppendingFormat:@", %@", value];
    }
    [self setValue:value forHTTPHeaderField:field.stringbyFormattingHTTPHeader];
    
    [[[NSMutableURLRequest alloc] init] setAllHTTPHeaderFields:nil];
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    if ( _headersAlreadySent ) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"HTTP headers have already been sent." userInfo:HTTPHeaders.copy];
        return;
    }
    [HTTPHeaders setObject:value forKey:field.stringbyFormattingHTTPHeader];
}

- (void)setAllHTTPHeaderFields:(NSDictionary *)headerFields
{
    [headerFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ( [key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]] ) {
            [self addValue:obj forHTTPHeaderField:key];
        }
    }];
}

- (void)setCookie:(NSHTTPCookie *)cookie
{
    if ( cookie != nil ) {
        [HTTPCookies setObject:cookie forKey:cookie.name];
    }
}

- (void)setCookie:(NSString*)name value:(NSString*)value expires:(NSDate*)expires path:(NSString*)path domain:(NSString*)domain secure:(BOOL)secure
{
    NSMutableDictionary* cookieProperties = [[NSMutableDictionary alloc] init];
    [cookieProperties setObject:name forKey:NSHTTPCookieName];
    [cookieProperties setObject:value forKey:NSHTTPCookieValue];
    if ( expires != nil ) {
        [cookieProperties setObject:expires forKey:NSHTTPCookieExpires];
    } else {
        [cookieProperties setObject:@"TRUE" forKey:NSHTTPCookieDiscard];
    }
    if ( path != nil ) {
        [cookieProperties setObject:path forKey:NSHTTPCookiePath];
    }
    [cookieProperties setObject:(domain == nil ? _HTTPRequest.serverVars[@"HTTP_HOST"] : domain ) forKey:NSHTTPCookieDomain];
    if ( secure ) {
        [cookieProperties setObject:@"TRUE" forKey:NSHTTPCookieSecure];
    }

    NSHTTPCookie* cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [self setCookie:cookie];
}

- (void)redirectToLocation:(NSString *)location withStatus:(NSUInteger)redirectStatus
{
    if ( _headersAlreadySent ) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"HTTP headers have already been sent." userInfo:HTTPHeaders.copy];
        return;
    }

    [self setHTTPStatus:redirectStatus];
    [self setValue:location forHTTPHeaderField:@"Location"];
    [self sendHTTPHeaders];
    [self finish];
}


- (void)write:(NSData*)data
{
    
    if ( _isRedirecting ) {
        return;
    }
    
    if ( !_headersAlreadySent ) {
        [self sendHTTPHeaders];
    }
    
    NSDictionary* userInfo = @{FKRequestKey: self.HTTPRequest.FCGIRequest, FKDataKey: data == nil ? [NSData data] : data };
    [[FKApplication sharedApplication] writeDataToStdout:userInfo];
}

- (void)writeString:(NSString *)string
{
    [self write:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)log:(NSData *)data
{
    NSDictionary* userInfo = @{FKRequestKey: self.HTTPRequest.FCGIRequest, FKDataKey: data == nil ? [NSData data] : data };
    [[FKApplication sharedApplication]  writeDataToStderr:userInfo];
}

- (void)logString:(NSString *)string
{
    [self log:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)finish
{
    if ( !_headersAlreadySent ) {
        [self sendHTTPHeaders];
    }
    [[FKApplication sharedApplication]  finishRequest:self.HTTPRequest.FCGIRequest];
}



@end