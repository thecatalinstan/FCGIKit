//
//  FKConstants.h
//  FCGIKit
//
//  Created by Cătălin Stan on 13/10/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

enum {
	FKTerminateCancel = 0,
	FKTerminateNow    = 1,
	FKTerminateLater  = 2
};
typedef NSUInteger FKApplicationTerminateReply;

extern NSString* const FCGIKit;
extern NSString* const FKApplicationRunLoopMode;

extern NSString* const FKErrorKey;
extern NSString* const FKErrorFileKey;
extern NSString* const FKErrorLineKey;
extern NSString* const FKErrorDomain;

extern NSString* const FKMaxConnectionsKey;
extern NSString* const FKConnectionInfoKey;
extern NSString* const FKConnectionInfoPortKey;
extern NSString* const FKConnectionInfoInterfaceKey;
extern NSString* const FKConnectionInfoSocketKey;

extern NSUInteger const FKDefaultMaxConnections;
extern NSString* const FKDefaultSocketPath;
extern NSUInteger const FKDefaultPortNumber;

extern NSString* const FKRecordKey;
extern NSString* const FKSocketKey;
extern NSString* const FKDataKey;
extern NSString* const FKRequestKey;
extern NSString* const FKResponseKey;
extern NSString* const FKResultKey;

extern NSString* const FKRoutesKey;
extern NSString* const FKRoutePathKey;
extern NSString* const FKRouteControllerKey;
extern NSString* const FKRouteNibNameKey;
extern NSString* const FKRouteUserInfoKey;

extern NSString* const FKFileNameKey;
extern NSString* const FKFileTmpNameKey;
extern NSString* const FKFileSizeKey;
extern NSString* const FKFileContentTypeKey;

extern NSString* const FKApplicationWillFinishLaunchingNotification;
extern NSString* const FKApplicationDidFinishLaunchingNotification;
extern NSString* const FKApplicationWillTerminateNotification;

