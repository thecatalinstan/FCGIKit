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
}

@property (nonatomic, retain) FCGIKitHTTPRequest* HTTPRequest;

- (id)initWithHTTPRequest:(FCGIKitHTTPRequest*)anHTTPRequest;
+ (id)requestWithHTTPRequest:(FCGIKitHTTPRequest*)anHTTPRequest;

- (void)write:(NSData*)data;
- (void)writeString:(NSString*)string;

- (void)log:(NSData*)data;
- (void)logString:(NSString*)string;

- (void)finish;

@end
