//
//  FCGIApplication.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIKit.h"
#import "FCGIApplicationDelegate.h"
#import "FCGIServer.h"
#import "FCGIRequest.h"
#import "FCGITypes.h"

FCGIApplication *FCGIApp;
extern int FCGIApplicationMain(int argc, const char **argv, id<FCGIApplicationDelegate> delegate);
void handleSIGTERM(int signum);

@interface FCGIApplication : NSObject {
    id<FCGIApplicationDelegate> _delegate;
    NSUInteger _maxConnections;
    BOOL _isRunning;
    NSMutableArray* _workerThreads;
    NSMutableSet* _requestIDs;
    NSMutableDictionary* _environment;
    
    BOOL firstRunCompleted;
    BOOL shouldKeepRunning;
    BOOL isWaitingOnTerminateLaterReply;
    NSTimer* waitingOnTerminateLaterReplyTimer;
    CFRunLoopObserverRef mainRunLoopObserver;
    
    NSFileHandle* inputStreamFileHandle;
    FCGIServer* server;
}

@property (assign) id<FCGIApplicationDelegate> delegate;
@property (assign) NSUInteger maxConnections;
@property (readonly) BOOL isRunning;
@property (retain) NSMutableArray* workerThreads;
@property (retain) NSMutableSet* requestIDs;
@property (retain) NSMutableDictionary* environment;

+ (FCGIApplication *)sharedApplication;

- (NSDictionary*)infoDictionary;

- (void)terminate:(id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (void)run;
- (void)stop:(id)sender;

- (void)presentError:(NSError*)error;

@end
