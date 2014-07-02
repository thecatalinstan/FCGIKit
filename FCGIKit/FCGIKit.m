//
//  FCGIKit.m
//  FCGIKit
//
//  Created by Cătălin Stan on 4/27/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIKit.h"

NSString* const FCGIKit = @"FCGIKit";
NSString* const FKApplicationRunLoopMode = @"NSRunLoopCommonModes"; // This is a cheap hack. Will change to a custom runloop mode at some point

NSString* const FKErrorKey = @"FKError";
NSString* const FKErrorFileKey = @"FKErrorFile";
NSString* const FKErrorLineKey = @"FKErrorLine";
NSString* const FKErrorDomain = @"FKErrorDomain";

NSString* const FKMaxConnectionsKey = @"FKMaxConnections";
NSString* const FKConnectionInfoKey = @"FKConnectionInfo";
NSString* const FKConnectionInfoPortKey = @"FKConnectionInfoPort";
NSString* const FKConnectionInfoInterfaceKey = @"FKConnectionInfoInterface";
NSString* const FKConnectionInfoSocketKey = @"FKConnectionInfoSocket";

NSUInteger const FKDefaultMaxConnections = 150;
NSString* const FKDefaultSocketPath = @"/tmp/FCGIKit.sock";
NSUInteger const FKDefaultPortNumber = 10000;

NSString* const FKRecordKey = @"FKRecord";
NSString* const FKSocketKey = @"FKSocket";
NSString* const FKDataKey = @"FKData";
NSString* const FKRequestKey = @"FKRequest";
NSString* const FKResponseKey = @"FKResponse";
NSString* const FKResultKey = @"FKResult";

NSString* const FKRoutesKey = @"FKRoutes";
NSString* const FKRoutePathKey = @"FKRoutePath";
NSString* const FKRouteControllerKey = @"FKRouteController";
NSString* const FKRouteNibNameKey = @"FKRouteNibName";
NSString* const FKRouteUserInfoKey = @"FKRouteUserInfo";

NSString* const FKFileNameKey = @"FKFileName";
NSString* const FKFileTmpNameKey = @"FKFileTmpName";
NSString* const FKFileSizeKey = @"FKFileSize";
NSString* const FKFileContentTypeKey = @"FKFileContentType";

NSString* const FKApplicationWillFinishLaunchingNotification = @"FKApplicationWillFinishLaunchingNotification";
NSString* const FKApplicationDidFinishLaunchingNotification = @"FKApplicationDidFinishLaunchingNotification";
NSString* const FKApplicationWillTerminateNotification = @"FKApplicationWillTerminateNotification";