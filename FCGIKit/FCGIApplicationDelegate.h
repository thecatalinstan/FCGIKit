//
//  FCGIApplicationDelegate.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIKit.h"

@class FCGIApplication, FCGIKitHTTPRequest, FCGIKitHTTPResponse;

@protocol FCGIApplicationDelegate <NSObject>

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationWillSendResponse:(NSDictionary*)userInfo;

@optional

- (NSError *)application:(FCGIApplication *)application willPresentError:(NSError *)error;

- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (FCGIApplicationTerminateReply)applicationShouldTerminate:(FCGIApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

- (void)applicationDidReceiveRequest:(NSDictionary*)userInfo;

@end