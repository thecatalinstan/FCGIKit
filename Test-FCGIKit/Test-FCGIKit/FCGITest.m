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
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    return FCGITerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)applicationDidReceiveRequestParameters:(FCGIRequest *)request
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)applicationDidReceiveRequest:(FCGIRequest *)request
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
//    NSLog(@"%s%@%@", __PRETTY_FUNCTION__, request, [NSThread currentThread]);
    NSLog(@"%@%@", [NSThread currentThread], [[NSThread currentThread] threadDictionary]);
    
    NSString* requestId = [[[NSString stringWithFormat:@"Thread: %@\nIs Main thread: %hhd\nRequest: %@", [NSThread currentThread], [[NSThread currentThread] isMainThread], request] stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"] stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    
    [request writeDataToStdout:[@"Status: 200\nContent-Type: text/html;charset=utf-8\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request writeDataToStdout: [[NSString stringWithFormat: @"<pre>%@</pre>", requestId] dataUsingEncoding:NSUTF8StringEncoding]];
    [request writeDataToStdout:[ [NSString stringWithFormat:@"<pre>%@</pre>", request.parameters] dataUsingEncoding:NSUTF8StringEncoding]];
    [request doneWithProtocolStatus:FCGI_REQUEST_COMPLETE applicationStatus:0];
}




@end