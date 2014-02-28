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
//    NSLog(@"%@", NSStringFromSelector(_cmd));

}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
//    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:17.0f target:self selector:@selector(terminate) userInfo:nil repeats:NO] forMode:FCGIKitApplicationRunLoopMode];
//    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)terminate
{
    [FCGIApp terminate:self];
}

- (void)reply
{
    [FCGIApp replyToApplicationShouldTerminate:YES];
}

//NSMutableArray* _workerThreads;

- (FCGIApplicationTerminateReply)applicationShouldTerminate:(FCGIApplication *)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
//    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:5.0f target:self selector:@selector(reply) userInfo:nil repeats:NO] forMode:FCGIKitApplicationRunLoopMode];
    return FCGITerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
//    NSLog(@"%@", NSStringFromSelector(_cmd));
}

@end