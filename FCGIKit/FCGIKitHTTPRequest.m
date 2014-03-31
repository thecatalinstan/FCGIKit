//
//  FCGIKitHTTPRequest.m
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitHTTPRequest.h"
#import "FCGIRequest.h"

@implementation FCGIKitHTTPRequest

@synthesize FCGIRequest = _FCGIRequest;

- (id)initWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
    self = [self init];
    if ( self != nil ) {
        _FCGIRequest = anFCGIRequest;
    }
    return self;
}

+ (id)requestWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
    return [[FCGIKitHTTPRequest alloc] initWithFCGIRequest:anFCGIRequest];
}

@end
