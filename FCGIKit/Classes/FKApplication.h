//
//  FCGIApplication.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FKApplicationDelegate.h"
#import "AsyncSocket.h"

#define FCGIRecordFixedLengthPartLength 8
#define FCGITimeout 5

extern NSString* const FKApplicationRunLoopMode;

extern NSString* const FCGIKit;

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
extern NSString* const FKApplicationStatusKey;
extern NSString* const FKProtocolStatusKey;

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

typedef id (^FKAppBackgroundOperationBlock)(NSDictionary *userInfo);
typedef void (^FKAppBackgroundOperationCompletionBlock)(NSDictionary *userInfo);

@class FCGIRequest, FKHTTPRequest, FKHTTPResponse;
@protocol AsyncSocketDelegate;

FKApplication *FKApp;
extern int FKApplicationMain(int argc, const char **argv, id<FKApplicationDelegate> delegate);

@interface FKApplication : NSObject<AsyncSocketDelegate> {
    NSObject<FKApplicationDelegate> *_delegate;
    NSUInteger _maxConnections;
    NSString* _socketPath;
    NSUInteger _portNumber;
    NSString* _listenIngInterface;
    
    BOOL _isListeningOnUnixSocket;
    BOOL _isListeningOnAllInterfaces;
    BOOL _isRunning;
    
    NSMutableDictionary* _environment;
    
    BOOL firstRunCompleted;
    BOOL shouldKeepRunning;
    BOOL isWaitingOnTerminateLaterReply;
    
    NSTimer* waitingOnTerminateLaterReplyTimer;
    CFRunLoopObserverRef mainRunLoopObserver;
    
    AsyncSocket *_listenSocket;
    NSMutableArray *_connectedSockets;    
    NSMutableDictionary* _currentRequests;
    
    NSThread *_listeningSocketThread;
    
    NSArray* _startupArguments;
    
    NSMutableDictionary* _viewControllers;
}

@property (nonatomic, assign) NSObject<FKApplicationDelegate> *delegate;
@property (atomic, assign) NSUInteger maxConnections;
@property (atomic, assign) NSUInteger portNumber;
@property (nonatomic, retain) NSString* listeningInterface;
@property (nonatomic, retain) NSString* socketPath;
@property (atomic, readonly) BOOL isListeningOnUnixSocket;
@property (atomic, readonly) BOOL isListeningOnAllInterfaces;
@property (atomic, readonly) BOOL isRunning;
@property (nonatomic, retain) NSMutableSet* requestIDs;
@property (nonatomic, retain) AsyncSocket* listenSocket;
@property (nonatomic, retain) NSMutableArray* connectedSockets;
@property (nonatomic, retain) NSMutableDictionary* currentRequests;
@property (nonatomic, retain) NSThread* listeningSocketThread;
@property (nonatomic, readonly, retain) NSArray* startupArguments;
@property (nonatomic, retain) NSMutableDictionary* viewControllers;

+ (FKApplication *)sharedApplication;

- initWithArguments:(const char **)argv count:(int)argc;

- (NSDictionary*)infoDictionary;

- (void)terminate:(id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (void)run;
- (void)stop:(id)sender;

- (void)presentError:(NSError*)error;

- (void)writeDataToStderr:(NSDictionary *)info;
- (void)writeDataToStdout:(NSDictionary *)info;
- (void)finishRequest:(FCGIRequest*)request;
- (void)finishRequestWithError:(NSDictionary*)userInfo;

- (NSDictionary*)dumpConfig;

- (void)performBackgroundSelector:(SEL)aSelector onTarget:(id)target userInfo:(NSDictionary *)userInfo didEndSelector:(SEL)didEndSelector;
- (void)performBackgroundDidEndSelector:(SEL)didEndSelector onTarget:(id)target userInfo:(NSDictionary*)userInfo;

- (void)performBackgroundOperation:(FKAppBackgroundOperationBlock)block withCompletion:(FKAppBackgroundOperationCompletionBlock)completion userInfo:(NSDictionary*)userInfo;

- (NSString*)temporaryDirectoryLocation;

@end