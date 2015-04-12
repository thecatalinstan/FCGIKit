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
    NSMutableData* body;
}

@property (nonatomic, retain) FCGIRequest* FCGIRequest;
@property (nonatomic, readonly, retain) NSURL* url;
@property (nonatomic, readonly, copy) NSDictionary *parameters;
@property (nonatomic, readonly, copy) NSDictionary *get;
@property (nonatomic, readonly, copy) NSDictionary *post;
@property (nonatomic, readonly, copy) NSDictionary *cookie;
@property (nonatomic, readonly, copy) NSDictionary *files;

- (instancetype)initWithFCGIRequest:(FCGIRequest*)anFCGIRequest;
+ (instancetype)requestWithFCGIRequest:(FCGIRequest*)anFCGIRequest;


@end
