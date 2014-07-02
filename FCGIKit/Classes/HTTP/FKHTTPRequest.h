//
//  FCGIKitHTTPRequest.h
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCGIRequest;

@interface FKHTTPRequest : NSObject {
    FCGIRequest* _FCGIRequest;
    NSDictionary* _server;
    NSDictionary* _get;
    NSDictionary* _post;
    NSDictionary* _files;
    NSDictionary* _cookie;

    NSMutableData* body;
    
    NSURL* _url;
}

@property (nonatomic, retain) FCGIRequest* FCGIRequest;
@property (nonatomic, readonly, retain) NSURL* url;

- (id)initWithFCGIRequest:(FCGIRequest*)anFCGIRequest;
+ (id)requestWithFCGIRequest:(FCGIRequest*)anFCGIRequest;

- (NSDictionary*)serverVars;
- (NSDictionary*)getVars;
- (NSDictionary*)postVars;
- (NSDictionary*)cookieVars;
- (NSDictionary*)files;
    
@end