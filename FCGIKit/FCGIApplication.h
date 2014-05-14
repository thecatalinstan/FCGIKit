//
//  FCGIApplication.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIApplicationDelegate.h"
#import "AsyncSocket.h"

#define FCGIRecordFixedLengthPartLength 8
#define FCGITimeout 5

enum _FCGISocketTag
{
    FCGIRecordAwaitingHeaderTag,
    FCGIRecordAwaitingContentAndPaddingTag
} FCGISocketTag;

@class FCGIRequest;
@protocol AsyncSocketDelegate;

FCGIApplication *FCGIApp;
extern int FCGIApplicationMain(int argc, const char **argv, id<FCGIApplicationDelegate> delegate);
void handleSIGTERM(int signum);

@interface FCGIApplication : NSObject<AsyncSocketDelegate> {
    NSObject<FCGIApplicationDelegate> *_delegate;
    NSUInteger _maxConnections;
    NSString* _socketPath;
    NSUInteger _portNumber;
    NSString* _listenIngInterface;
    NSUInteger _initialThreads;
    NSUInteger _maxThreads;
    NSUInteger _requestsPerThread;
    
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
    NSMutableArray *_workerThreads;
    
    NSThread *_listeningSocketThread;
}

@property (assign) NSObject<FCGIApplicationDelegate> *delegate;
@property (assign) NSUInteger maxConnections;
@property (assign) NSUInteger portNumber;
@property (retain) NSString* listeningInterface;
@property (retain) NSString* socketPath;
@property (assign) NSUInteger initialThreads;
@property (assign) NSUInteger maxThreads;
@property (assign) NSUInteger requestsPerThread;
@property (readonly) BOOL isListeningOnUnixSocket;
@property (readonly) BOOL isListeningOnAllInterfaces;
@property (readonly) BOOL isRunning;
@property (retain) NSMutableArray* workerThreads;
@property (retain) NSMutableSet* requestIDs;
@property (retain) NSMutableDictionary* environment;
@property (retain) AsyncSocket* listenSocket;
@property (retain) NSMutableArray* connectedSockets;
@property (retain) NSMutableDictionary* currentRequests;
@property (retain) NSThread* listeningSocketThread;

+ (FCGIApplication *)sharedApplication;

- (NSDictionary*)infoDictionary;

- (void)terminate:(id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (void)run;
- (void)stop:(id)sender;

- (void)presentError:(NSError*)error;

- (void)writeDataToStderr:(NSDictionary *)info;
- (void)writeDataToStdout:(NSDictionary *)info;
- (void)finishRequest:(FCGIRequest*)request;

- (NSDictionary*)dumpConfig;

- (void)performBackgroundSelector:(SEL)aSelector onTarget:(id)target userInfo:(NSDictionary *)userInfo didEndSelector:(SEL)didEndSelector;
- (void)performBackgroundDidEndSelector:(SEL)didEndSelector onTarget:(id)target userInfo:(NSDictionary*)userInfo;

@end