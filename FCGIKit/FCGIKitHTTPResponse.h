//
//  FCGIKitHTTPResponse.h
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCGIKitHTTPRequest, FCGIRequest;

@interface FCGIKitHTTPResponse : NSObject {
    FCGIKitHTTPRequest* _HTTPRequest;

    NSMutableDictionary* HTTPHeaders;

    BOOL _headersAlreadySent;
    NSUInteger _HTTPStatus;
    
    BOOL _isRedirecting;
}

@property (nonatomic, retain) FCGIKitHTTPRequest* HTTPRequest;
@property (atomic, readonly) BOOL headersAlreadySent;
@property (atomic, assign) NSUInteger HTTPStatus;
@property (atomic, readonly) BOOL isRedirecting;

- (id)initWithHTTPRequest:(FCGIKitHTTPRequest*)anHTTPRequest;
+ (id)responseWithHTTPRequest:(FCGIKitHTTPRequest*)anHTTPRequest;

- (void)write:(NSData*)data;
- (void)writeString:(NSString*)string;

- (void)log:(NSData*)data;
- (void)logString:(NSString*)string;

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

- (void)redirectToLocation:(NSString *)location withStatus:(NSUInteger)redirectStatus;

- (void)finish;

@end
