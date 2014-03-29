//
//  FCGIApplication.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIKit.h"
#import "FCGIApplicationDelegate.h"
#import "AsyncSocket.h"
#import "FCGIRecord.h"
#import "FCGIBeginRequestRecord.h"
#import "FCGIParamsRecord.h"
#import "FCGIByteStreamRecord.h"
#import "FCGIRequest.h"
#import "FCGIThread.h"


#define FCGIRecordFixedLengthPartLength 8
#define FCGITimeout 5

enum _FCGISocketTag
{
    FCGIRecordAwaitingHeaderTag,
    FCGIRecordAwaitingContentAndPaddingTag
} FCGISocketTag;

@class FCGIRequest;

FCGIApplication *FCGIApp;
extern int FCGIApplicationMain(int argc, const char **argv, id<FCGIApplicationDelegate> delegate);
void handleSIGTERM(int signum);

@interface FCGIApplication : NSObject<AsyncSocketDelegate> {
    id<FCGIApplicationDelegate> _delegate;
    NSUInteger _maxConnections;
    NSString* _socketPath;
    NSUInteger _portNumber;
    
    BOOL _isListeningOnUnixSocket;
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
}

@property (assign) id<FCGIApplicationDelegate> delegate;
@property (assign) NSUInteger maxConnections;
@property (assign) NSUInteger portNumber;
@property (retain) NSString* socketPath;
@property (readonly) BOOL isListeningOnUnixSocket;
@property (readonly) BOOL isRunning;
@property (retain) NSMutableArray* workerThreads;
@property (retain) NSMutableSet* requestIDs;
@property (retain) NSMutableDictionary* environment;
@property (retain) AsyncSocket* listenSocket;
@property (retain) NSMutableArray* connectedSockets;
@property (retain) NSMutableDictionary* currentRequests;

+ (FCGIApplication *)sharedApplication;

- (NSDictionary*)infoDictionary;

- (void)terminate:(id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (void)run;
- (void)stop:(id)sender;

- (void)presentError:(NSError*)error;

@end
