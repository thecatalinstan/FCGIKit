//
//  FCGIKitHTTPResponse.h
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKHTTPRequest, FCGIRequest;

@interface FCGIKitHTTPResponse : NSObject {
    FKHTTPRequest* _HTTPRequest;

    NSMutableDictionary* HTTPHeaders;
    NSMutableDictionary* HTTPCookies;

    BOOL _headersAlreadySent;
    NSUInteger _HTTPStatus;
    
    BOOL _isRedirecting;
}

@property (nonatomic, retain) FKHTTPRequest* HTTPRequest;
@property (atomic, readonly) BOOL headersAlreadySent;
@property (atomic, assign) NSUInteger HTTPStatus;
@property (atomic, readonly) BOOL isRedirecting;

- (id)initWithHTTPRequest:(FKHTTPRequest*)anHTTPRequest;
+ (id)responseWithHTTPRequest:(FKHTTPRequest*)anHTTPRequest;

- (void)write:(NSData*)data;
- (void)writeString:(NSString*)string;

- (void)log:(NSData*)data;
- (void)logString:(NSString*)string;

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setAllHTTPHeaderFields:(NSDictionary*)headerFields;

- (void)setCookie:(NSHTTPCookie*)cookie;
- (void)setCookie:(NSString*)name value:(NSString*)value expires:(NSDate*)expires path:(NSString*)path domain:(NSString*)domain secure:(BOOL)secure;

- (void)redirectToLocation:(NSString *)location withStatus:(NSUInteger)redirectStatus;

- (void)finish;

@end
