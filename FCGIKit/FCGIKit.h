//
//  FCGIKit.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/27/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

enum {
    FCGITerminateCancel = 0,
    FCGITerminateNow    = 1,
    FCGITerminateLater  = 2
};
typedef NSUInteger FCGIApplicationTerminateReply;

extern NSString* const FCGIKit;
extern NSString* const FCGIKitApplicationRunLoopMode;
extern NSString* const FCGIKitErrorFileKey;
extern NSString* const FCGIKitErrorLineKey;
extern NSString* const FCGIKitMaxConnectionsKey;
extern NSString* const FCGIKitConnectionInfoKey;
extern NSString* const FCGIKitConnectionInfoPortKey;
extern NSString* const FCGIKitConnectionInfoSocketKey;
extern NSString* const FCGIKitRequestsPerThreadKey;
extern NSString* const FCGIKitMaxThreadsKey;
extern NSString* const FCGIKitInitialThreadsKey;

extern NSUInteger const FCGIKitDefaultRequestsPerThread;
extern NSUInteger const FCGIKitDefaultMaxThreads;
extern NSUInteger const FCGIKitDefaultInitialThreads;
extern NSUInteger const FCGIKitDefaultMaxConnections;
extern NSString* const FCGIKitDefaultSocketPath;
extern NSUInteger const FCGIKitDefaultPortNumber;

extern NSString* const FCGIKitRecordKey;
extern NSString* const FCGIKitSocketKey;
extern NSString* const FCGIKitDataKey;
extern NSString* const FCGIKitRequestKey;
extern NSString* const FCGIKitResponseKey;

extern NSString* const FCGIKitApplicationWillFinishLaunchingNotification;
extern NSString* const FCGIKitApplicationDidFinishLaunchingNotification;
extern NSString* const FCGIKitApplicationWillTerminateNotification;

void mainRunLoopObserverCallback( CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info );