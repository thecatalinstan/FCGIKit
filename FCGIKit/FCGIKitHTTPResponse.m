//
//  FCGIKitHTTPResponse.m
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitHTTPResponse.h"
#import "FCGIApplication.h"
#import "FCGIKitHTTPRequest.h"
#import "FCGIRequest.h"
#import "FCGIKit.h"


@implementation FCGIKitHTTPResponse

@synthesize HTTPRequest = _HTTPRequest;

- (id)initWithHTTPRequest:(FCGIKitHTTPRequest *)anHTTPRequest
{
    self = [self init];
    if ( self != nil ) {
        _HTTPRequest = anHTTPRequest;
    }
    return self;
}

+ (id)requestWithHTTPRequest:(FCGIKitHTTPRequest *)anHTTPRequest
{
    return [[FCGIKitHTTPResponse alloc] initWithHTTPRequest:anHTTPRequest];
}

- (void)write:(NSData*)data
{
    NSDictionary* userInfo = @{FCGIKitRequestKey: self.HTTPRequest.FCGIRequest, FCGIKitDataKey: data };
    [[FCGIApplication sharedApplication]  writeDataToStdout:userInfo];
//    [[FCGIApplication sharedApplication] performSelector:@selector(writeDataToStdout:) onThread:[[FCGIApplication sharedApplication] listeningSocketThread] withObject:userInfo waitUntilDone:NO modes:@[FCGIKitApplicationRunLoopMode]];
}

- (void)writeString:(NSString *)string
{
    [self write:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)log:(NSData *)data
{
    NSDictionary* userInfo = @{FCGIKitRequestKey: self.HTTPRequest.FCGIRequest, FCGIKitDataKey: data };
    [[FCGIApplication sharedApplication]  writeDataToStderr:userInfo];
//    [[FCGIApplication sharedApplication] performSelector:@selector(writeDataToStderr:) onThread:[[FCGIApplication sharedApplication] listeningSocketThread] withObject:userInfo waitUntilDone:NO modes:@[FCGIKitApplicationRunLoopMode]];
}

- (void)logString:(NSString *)string
{
    [self log:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)finish
{
    [[FCGIApplication sharedApplication]  finishRequest:self.HTTPRequest.FCGIRequest];
//    [[FCGIApplication sharedApplication] performSelector:@selector(finishRequest:) onThread:[[FCGIApplication sharedApplication] listeningSocketThread] withObject:self.HTTPRequest.FCGIRequest waitUntilDone:NO modes:@[FCGIKitApplicationRunLoopMode]];
}


@end
