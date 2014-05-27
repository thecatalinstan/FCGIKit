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

- (void)application:(FCGIApplication *)application didReceiveRequest:(NSDictionary *)userInfo
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
}

- (void)application:(FCGIApplication *)application didPrepareResponse:(NSDictionary *)userInfo
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
}

- (void)application:(FCGIApplication *)application presentViewController:(FCGIKitViewController *)viewController
{
//    NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    [viewController.response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"content-type"];
    
    [viewController presentViewController:YES];
    [viewController.response finish];
}

- (NSString *)routeLookupURIForRequest:(FCGIKitHTTPRequest *)request
{
//    NSLog(@"%s %@", __PRETTY_FUNCTION__, request.serverVars[@"REQUEST_URI"]);
//    NSString* stub;
//    if ( request.getVars[@"page"] != nil ) {
//        stub = request.getVars[@"page"];
//    } else{
//        stub = @"*";
//    }
//    return [@"/" stringByAppendingString:stub];
    return request.serverVars[@"REQUEST_URI"];
}


@end