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
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
}

- (FKApplicationTerminateReply)applicationShouldTerminate:(FKApplication *)sender
{
    return FKTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
}

- (void)application:(FKApplication *)application didReceiveRequest:(NSDictionary *)userInfo
{
}

- (void)application:(FKApplication *)application didPrepareResponse:(NSDictionary *)userInfo
{
}

- (void)application:(FKApplication *)application presentViewController:(FKViewController *)viewController
{
    [viewController.response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"content-type"];
    [viewController presentViewController:YES];
    [viewController.response finish];
}

- (NSString *)routeLookupURIForRequest:(FKHTTPRequest *)request
{
    return request.serverVars[@"REQUEST_URI"];
}

@end