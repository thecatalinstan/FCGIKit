//
//  FCGIApplicationDelegate.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIKit.h"

@class FCGIApplication, FCGIKitHTTPRequest, FCGIKitHTTPResponse, FCGIKitViewController;

@protocol FKApplicationDelegate <NSObject>

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)application:(FCGIApplication*)application presentViewController:(FCGIKitViewController*)viewController;

@optional
- (NSError *)application:(FCGIApplication *)application willPresentError:(NSError *)error;

- (void)applicationWillFinishLaunching:(NSNotification *)notification;

- (FCGIApplicationTerminateReply)applicationShouldTerminate:(FCGIApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

- (void)application:(FCGIApplication*)application didReceiveRequest:(NSDictionary*)userInfo;
- (void)application:(FCGIApplication*)application didPrepareResponse:(NSDictionary*)userInfo;

- (NSString *)routeLookupURIForRequest:(FCGIKitHTTPRequest *)request;

@end