//
//  FCGIApplicationDelegate.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIKit.h"

@class FKApplication, FKHTTPRequest, FKHTTPResponse, FKViewController;

@protocol FKApplicationDelegate <NSObject>

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)application:(FKApplication*)application presentViewController:(FKViewController*)viewController;

@optional
- (NSError *)application:(FKApplication *)application willPresentError:(NSError *)error;

- (void)applicationWillFinishLaunching:(NSNotification *)notification;

- (FKApplicationTerminateReply)applicationShouldTerminate:(FKApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

- (void)application:(FKApplication*)application didReceiveRequest:(NSDictionary*)userInfo;
- (void)application:(FKApplication*)application didPrepareResponse:(NSDictionary*)userInfo;

- (NSString *)routeLookupURIForRequest:(FKHTTPRequest *)request;

@end