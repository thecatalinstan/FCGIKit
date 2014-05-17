//
//  FCGIKit.m
//  FCGIKit
//
//  Created by Cătălin Stan on 4/27/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIKit.h"

NSString* const FCGIKit = @"FCGIKit";
NSString* const FCGIKitApplicationRunLoopMode = @"NSRunLoopCommonModes"; // This is a cheap hack. Will change to a custom runloop mode at some point
NSString* const FCGIKitErrorFileKey = @"FCGIKitErrorFile";
NSString* const FCGIKitErrorLineKey = @"FCGIKitErrorLine";
NSString* const FCGIKitMaxConnectionsKey = @"FCGIKitMaxConnections";
NSString* const FCGIKitConnectionInfoKey = @"FCGIKitConnectionInfo";
NSString* const FCGIKitConnectionInfoPortKey = @"FCGIKitConnectionInfoPort";
NSString* const FCGIKitConnectionInfoInterfaceKey = @"FCGIKitConnectionInfoInterface";
NSString* const FCGIKitConnectionInfoSocketKey = @"FCGIKitConnectionInfoSocket";

NSUInteger const FCGIKitDefaultMaxConnections = 150;
NSString* const FCGIKitDefaultSocketPath = @"/tmp/fcgikit.sock";
NSUInteger const FCGIKitDefaultPortNumber = 10000;

NSString* const FCGIKitRecordKey = @"FCGIKitRecord";
NSString* const FCGIKitSocketKey = @"FCGIKitSocket";
NSString* const FCGIKitDataKey = @"FCGIKitData";
NSString* const FCGIKitRequestKey = @"FCGIKitRequest";
NSString* const FCGIKitResponseKey = @"FCGIKitResponse";
NSString* const FCGIKitResultKey = @"FCGIKitResult";

NSString* const FCGIKitFileNameKey = @"FCGIKitFileName";
NSString* const FCGIKitFileTmpNameKey = @"FCGIKitFileTmpName";
NSString* const FCGIKitFileSizeKey = @"FCGIKitFileSize";
NSString* const FCGIKitFileContentTypeKey = @"FCGIKitFileContentType";

NSString* const FCGIKitApplicationWillFinishLaunchingNotification = @"FCGIKitApplicationWillFinishLaunchingNotification";
NSString* const FCGIKitApplicationDidFinishLaunchingNotification = @"FCGIKitApplicationDidFinishLaunchingNotification";
NSString* const FCGIKitApplicationWillTerminateNotification = @"FCGIKitApplicationWillTerminateNotification";

void mainRunLoopObserverCallback( CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info ) {
    return;
    
    CFRunLoopActivity currentActivity = activity;

    switch (currentActivity) {
        case kCFRunLoopEntry:
            NSLog(@"* Waiting for events: %@\n", [NSThread currentThread]);
            break;
        case kCFRunLoopAfterWaiting:
//        case kCFRunLoopExit:
            NSLog(@"* Processed event: %@\n", [NSThread currentThread]);
            break;
        default:
            break;
    }
    
    return;

    switch (currentActivity) {
        case kCFRunLoopEntry:
            NSLog(@"kCFRunLoopEntry: %@\n", [NSThread currentThread]);
            break;
            
        case kCFRunLoopBeforeTimers:
            NSLog(@"kCFRunLoopBeforeTimers: %@\n", [NSThread currentThread]);
            break;
            
        case kCFRunLoopBeforeSources:
            NSLog(@"kCFRunLoopBeforeSources: %@\n", [NSThread currentThread]);
            break;
            
        case kCFRunLoopBeforeWaiting:
            NSLog(@"kCFRunLoopBeforeWaiting: %@\n", [NSThread currentThread]);
            break;
            
        case kCFRunLoopAfterWaiting:
            NSLog(@"kCFRunLoopAfterWaiting: %@\n", [NSThread currentThread]);
            break;
            
        case kCFRunLoopExit:
            NSLog(@"kCFRunLoopExit: %@\n", [NSThread currentThread]);
            break;
            
        default:
            NSLog(@"Activity not recognized!: %@\n", [NSThread currentThread]);
            break;
    }
}