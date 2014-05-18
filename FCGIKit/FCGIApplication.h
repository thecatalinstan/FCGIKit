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
}

@property (nonatomic, assign) NSObject<FCGIApplicationDelegate> *delegate;
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

+ (FCGIApplication *)sharedApplication;

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

- (NSString*)temporaryDirectoryLocation;

@end