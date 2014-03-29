//
//  FCGITest.m
//  Test-FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGITest.h"

@implementation FCGITest

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (FCGIApplicationTerminateReply)applicationShouldTerminate:(FCGIApplication *)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return FCGITerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)applicationDidReceiveRequestParameters:(FCGIRequest *)request
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)applicationDidReceiveRequest:(FCGIRequest *)request
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
//    [request writeDataToStdout:[@"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 8\r\n\r\nTest" dataUsingEncoding:NSASCIIStringEncoding]];
//    [request writeDataToStdout:[@"Test" dataUsingEncoding:NSASCIIStringEncoding]];
//    [request doneWithProtocolStatus:FCGI_REQUEST_COMPLETE applicationStatus:0];
}




@end