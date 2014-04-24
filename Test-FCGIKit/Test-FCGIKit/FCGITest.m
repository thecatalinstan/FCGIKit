//
//  FCGITest.m
//  Test-FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGITest.h"
#import <CoreServices/CoreServices.h>

@implementation FCGITest

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (FCGIApplicationTerminateReply)applicationShouldTerminate:(FCGIApplication *)sender
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    return FCGITerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)applicationDidReceiveRequest:(NSDictionary *)userInfo
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
}

- (void)applicationWillSendResponse:(NSDictionary *)userInfo
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    
    FCGIKitHTTPRequest* request = [userInfo objectForKey:FCGIKitRequestKey];
    FCGIKitHTTPResponse* response = [userInfo objectForKey:FCGIKitResponseKey];
    
    NSDictionary* requestDictionary = @{ @"GET": request.getFields,
                                         @"POST": request.postFields };
    
    // Headers
    [response writeString:@"Status: 200\nContent-Type: text/html;charset=utf-8\n\n"];
    
    // Body
    [response writeString:[NSString stringWithFormat:@"<h1>%s</h1>", __PRETTY_FUNCTION__]];
    [response writeString:[NSString stringWithFormat:@"<h3>Thread: %@<br/>", [NSThread currentThread]]];
    [response writeString:[NSString stringWithFormat:@"Sockets:%lu<br/>", (unsigned long)[[FCGIApp connectedSockets] count] ]];
    [response writeString:[NSString stringWithFormat:@"Current Proc Speed:%hd<br/>", CurrentProcessorSpeed()]];
    [response writeString:[NSString stringWithFormat:@"RequestID: %lu</h3>", request.FCGIRequest.hash]];
    [response writeString:[NSString stringWithFormat:@"<h2>Request:</h2><pre>%@</pre>", requestDictionary ]];
//    [response writeString:[NSString stringWithFormat:@"<h2>Current Requests:</h2><pre>%@</pre>", [FCGIApp currentRequests] ]];
    [response writeString:[NSString stringWithFormat:@"<h2>RequestIDs:</h2><pre>%@</pre>", [FCGIApp requestIDs] ]];
    [response writeString:[NSString stringWithFormat:@"<h2>Config:</h2><pre>%@</pre>", [[FCGIApplication sharedApplication] dumpConfig] ]];
    [response writeString:[NSString stringWithFormat:@"<h2>Parameters:</h2><pre>%@</pre>", request.serverFields]];

//    sleep(1);
    
    [response finish];
}


@end