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

@end