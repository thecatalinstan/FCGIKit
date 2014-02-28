//
//  FCGIApplicationDelegate.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIKit.h"

@class FCGIApplication;

@protocol FCGIApplicationDelegate <NSObject>

@optional

- (NSError *)application:(FCGIApplication *)application willPresentError:(NSError *)error;

- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (FCGIApplicationTerminateReply)applicationShouldTerminate:(FCGIApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

@end