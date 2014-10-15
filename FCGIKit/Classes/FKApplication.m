//
//  FCGIApplication.m
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import <objc/message.h>

#import "AsyncSocket.h"

#import "FKApplication.h"
#import "FCGIKit.h"
#import "FCGIRecord.h"
#import "FCGIBeginRequestRecord.h"
#import "FCGIParamsRecord.h"
#import "FCGIByteStreamRecord.h"
#import "FCGIRequest.h"
#import "FKHTTPRequest.h"
#import "FKHTTPResponse.h"
#import "FKBackgroundThread.h"
#import "FKRoute.h"
#import "FKRoutingCenter.h"
#import "FKNib.h"
#import "FKView.h"
#import "FKViewController.h"


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
NSString* const FKApplicationStatusKey = @"FKApplicationStatus";
NSString* const FKProtocolStatusKey = @"FKProtocolStatus";

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

void handleSIGTERM(int signum) {
    [FKApp performSelectorOnMainThread:@selector(terminate:) withObject:nil waitUntilDone:YES];
}

int FKApplicationMain(int argc, const char **argv, id<FKApplicationDelegate> delegate)
{
    (void)signal(SIGTERM, handleSIGTERM) ;
    FKApp = [[FKApplication alloc] initWithArguments:argv count:argc];
    [FKApp setDelegate:delegate];
    [FKApp run];
    return EXIT_SUCCESS;
}

void mainRunLoopObserverCallback( CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info )
{
#if LOG_RUNLOOP
    CFRunLoopActivity currentActivity = activity;
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
#endif
}

@interface FKApplication (Private)

- (void)quit;
- (void)cancelTermination;
- (void)startRunLoop;
- (void)finishLaunching;

- (void)startListening;
- (void)stopListening;

- (void)stopCurrentRunLoop;

- (void)handleRecord:(FCGIRecord*)record fromSocket:(AsyncSocket*)socket;

- (void)listeningThreadMain;

- (void)timerCallback;

- (id)threadInfoObjectForKey:(id)key;
- (void)setThreadInfoObject:(id)object forKey:(id)key;
- (void)removeThreadInfoObjectForKey:(id)key;

- (void)removeRequest:(FCGIRequest*)request;

- (NSString*)routeLookupURIForRequest:(FKHTTPRequest*)request;
- (FKViewController*)instantiateViewControllerForRoute:(FKRoute*)route userInfo:(NSDictionary*)userInfo;

@end

@implementation FKApplication(Private)

- (void)quit
{
    [self performSelector:@selector(stopListening) onThread:self.listeningSocketThread withObject:nil waitUntilDone:YES modes:@[FKApplicationRunLoopMode]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FKApplicationWillTerminateNotification object:self];
    CFRunLoopRemoveObserver([[NSRunLoop mainRunLoop] getCFRunLoop], mainRunLoopObserver, kCFRunLoopDefaultMode);
    CFRelease(mainRunLoopObserver);

    exit(EXIT_SUCCESS);
}

- (void)cancelTermination
{
    [self startRunLoop];
}

- (void)startListening
{
    NSError *error;
    BOOL listening = NO;

    if ( self.isListeningOnUnixSocket) {
        listening = [self.listenSocket acceptOnSocket:_socketPath error:&error];        
    } else {
        listening = [self.listenSocket acceptOnInterface:_isListeningOnAllInterfaces ? nil : _listenIngInterface port:_portNumber error:&error];
    }
    
    if ( !listening ) {
        [self presentError:error];
        [self terminate:self];
    }

}

- (void)stopListening
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [_listenSocket disconnect];
    _listenSocket = nil;

    // Stop any client connections
    NSUInteger i;
    for(i = 0; i < [self.connectedSockets count]; i++) {
        [[self.connectedSockets objectAtIndex:i] disconnect];
    }
}

- (void)finishLaunching
{
    if ( [self.infoDictionary.allKeys containsObject:FKMaxConnectionsKey] ) {
        _maxConnections = MAX(1, ((NSNumber*) [self.infoDictionary valueForKey:FKMaxConnectionsKey]).integerValue);
    }
    
    if ( [self.infoDictionary.allKeys containsObject:FKConnectionInfoKey] ) {
        _portNumber = MIN(INT16_MAX, MAX(0, ((NSNumber*) [[self.infoDictionary objectForKey:FKConnectionInfoKey] valueForKey:FKConnectionInfoPortKey]).integerValue)) ;
        
        if ( [[[self.infoDictionary objectForKey:FKConnectionInfoKey] allKeys] containsObject:FKConnectionInfoInterfaceKey] ) {
            _listenIngInterface = [[self.infoDictionary objectForKey:FKConnectionInfoKey] objectForKey:FKConnectionInfoInterfaceKey];
        }
        
        _socketPath = [[self.infoDictionary objectForKey:FKConnectionInfoKey] objectForKey:FKConnectionInfoSocketKey];
    }
    _isListeningOnUnixSocket = _portNumber == 0;
    _isListeningOnAllInterfaces = _listenIngInterface.length == 0;
    
    _connectedSockets = [[NSMutableArray alloc] initWithCapacity:_maxConnections + 1];
    _currentRequests = [[NSMutableDictionary alloc] init];
    _viewControllers = [[NSMutableDictionary alloc] init];
    
    // Load the routes and cache all nib files involved
    NSMutableArray* nibNames = [NSMutableArray array];
    NSDictionary* routes = [[FKRoutingCenter sharedCenter] allRoutes];
    [routes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        FKRoute* route = obj;
        NSString* nibName = route.nibName == nil ? [NSStringFromClass(route.controllerClass) stringByReplacingOccurrencesOfString:@"Controller" withString:@""] : route.nibName;
        [nibNames addObject:nibName];
    }];
    [FKNib cacheNibNames:nibNames bundle:[NSBundle mainBundle]];
    
    // Create a run loop observer and attach it to the run loop.
    NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
    CFRunLoopObserverContext  context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    mainRunLoopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &mainRunLoopObserverCallback, &context);
    if (mainRunLoopObserver)
    {
        CFRunLoopRef cfLoop = [runLoop getCFRunLoop];
        CFRunLoopAddObserver(cfLoop, mainRunLoopObserver, kCFRunLoopDefaultMode);
    }
    
    // Let observers know that initialization is complete
    [[NSNotificationCenter defaultCenter] postNotificationName:FKApplicationWillFinishLaunchingNotification object:self];
}

- (void)startRunLoop
{
    shouldKeepRunning = YES;
    
    // Detatch a thread for the listening socket
    [self setListeningSocketThread: [[NSThread alloc] initWithTarget:self selector:@selector(listeningThreadMain) object:nil]];
    [self.listeningSocketThread setName:@"FCGIKitListeningThread"];
    [self.listeningSocketThread start];

    // All startup is complete, let the delegate know they can do their own init here
    [[NSNotificationCenter defaultCenter] postNotificationName:FKApplicationDidFinishLaunchingNotification object:self];
    
    NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
    [runLoop addTimer:[NSTimer timerWithTimeInterval:DBL_MAX target:self selector:@selector(timerCallback) userInfo:nil repeats:YES] forMode:FKApplicationRunLoopMode];
    while ( shouldKeepRunning && [runLoop runMode:FKApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
        _isRunning=YES;
    }
    
    _isRunning = NO;
}

- (void)stopCurrentRunLoop
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
}


-(void)handleRecord:(FCGIRecord*)record fromSocket:(AsyncSocket *)socket
{
    
//    NSLog(@"%s %@: %hu", __PRETTY_FUNCTION__, record.className, record.contentLength);
    if ([record isKindOfClass:[FCGIBeginRequestRecord class]]) {
        
        FCGIRequest* request = [[FCGIRequest alloc] initWithBeginRequestRecord:(FCGIBeginRequestRecord*)record];
        request.socket = socket;
        NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, socket.connectedPort];
        [_currentRequests setObject:request forKey:globalRequestId];
        [socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
        
    } else if ([record isKindOfClass:[FCGIParamsRecord class]]) {
        
        NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
        FCGIRequest* request = [_currentRequests objectForKey:globalRequestId];
        NSDictionary* params = [(FCGIParamsRecord*)record params];
        if ([params count] > 0) {
            [request.parameters addEntriesFromDictionary:params];
        } else {
            [self removeThreadInfoObjectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)socket.hash]];
            if ( _delegate && [_delegate respondsToSelector:@selector(application:didReceiveRequest:)] ) {
                [self performSelector:@selector(callDelegateDidReceiveRequest:) onThread:[NSThread currentThread] withObject:request waitUntilDone:NO modes:@[FKApplicationRunLoopMode]];
            }
        }
        [socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
        
    } else if ([record isKindOfClass:[FCGIByteStreamRecord class]]) {
        
        NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
        FCGIRequest* request = [_currentRequests objectForKey:globalRequestId];
        NSData* data = [(FCGIByteStreamRecord*)record data];
        if ( [data length] > 0 ) {
            [request.stdinData appendData:data];
            [socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
        } else {
            FKHTTPRequest* httpRequest = [FKHTTPRequest requestWithFCGIRequest:request];
            FKHTTPResponse* httpResponse = [FKHTTPResponse responseWithHTTPRequest:httpRequest];

			NSDictionary* userInfo = @{FKRequestKey: httpRequest, FKResponseKey: httpResponse};
            if ( _delegate && [_delegate respondsToSelector:@selector(application:didPrepareResponse:)] ) {
                [self performSelector:@selector(callDelegateDidPrepareResponse:) onThread:[NSThread currentThread] withObject:userInfo waitUntilDone:NO modes:@[FKApplicationRunLoopMode]];
            }
            
            // Determine the appropriate view controller
            NSString* requestURI = [self routeLookupURIForRequest:httpRequest];
            
            FKRoute* route = [[FKRoutingCenter sharedCenter] routeForRequestURI:requestURI];
            if ( route == nil ) {
                route = [[FKRoutingCenter sharedCenter] routeForRequestURI:@"/*"];
            }
            
			FKViewController* viewController = [self instantiateViewControllerForRoute:route userInfo:userInfo];
            if ( viewController != nil ) {
				
                if ( _delegate && [_delegate respondsToSelector:@selector(application:presentViewController:)] ) {
                    [self performSelector:@selector(callDelegatePresentViewController:) onThread:[NSThread currentThread] withObject:viewController waitUntilDone:NO modes:@[FKApplicationRunLoopMode]];
                }
				
			} else if ( _delegate && [_delegate respondsToSelector:@selector(application:didNotFindViewController:)]) {
				
				[self performSelector:@selector(callDelegateDidNotFindViewController:) onThread:[NSThread currentThread] withObject:userInfo waitUntilDone:NO modes:@[FKApplicationRunLoopMode]];
				
            } else {
				
                NSString* errorDescription = [NSString stringWithFormat:@"No view controller for request URI: %@", httpRequest.serverVars[@"DOCUMENT_URI"]];
                NSError* error = [NSError errorWithDomain:FKErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: errorDescription, FKErrorFileKey: @__FILE__, FKErrorLineKey: @__LINE__}];
                NSMutableDictionary* finishRequestUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
                finishRequestUserInfo[FKErrorKey] = error;
                [self performSelector:@selector(finishRequestWithError:) onThread:[NSThread currentThread] withObject:finishRequestUserInfo waitUntilDone:NO modes:@[FKApplicationRunLoopMode]];
				
            }
        }
    }
}

- (void)callDelegateDidReceiveRequest:(FCGIRequest*)request
{
    NSDictionary* userInfo = @{FKRequestKey:request};
    [_delegate application:self didReceiveRequest:userInfo];
}

- (void)callDelegateDidPrepareResponse:(NSDictionary*)userInfo
{
    [_delegate application:self didPrepareResponse:userInfo];
}

- (void)callDelegateDidNotFindViewController:(NSDictionary*)userInfo
{
	[_delegate application:self didNotFindViewController:userInfo];
}


- (void)callDelegatePresentViewController:(FKViewController*)viewController
{
    [_delegate application:self presentViewController:viewController];
}

- (void)callBackgroundDidEndSelector:(NSArray*)argsArray
{
    objc_msgSend(argsArray[1], NSSelectorFromString(argsArray[0]), argsArray[2]);
}

- (void)listeningThreadMain
{
    @autoreleasepool {
        _listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
        [_listenSocket setRunLoopModes:[NSArray arrayWithObject:FKApplicationRunLoopMode]];
        [self startListening];
        while ( shouldKeepRunning && [[NSRunLoop currentRunLoop] runMode:FKApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
        }
        [self stopListening];
    }
}

- (void)timerCallback
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
}

- (id)threadInfoObjectForKey:(id)key
{
    if ( [_listeningSocketThread.threadDictionary.allKeys containsObject:key] ) {
        return [_listeningSocketThread.threadDictionary objectForKey:key];
    } else {
        return nil;
    }
}

- (void)setThreadInfoObject:(id)object forKey:(id)key
{
    [_listeningSocketThread.threadDictionary setObject:object forKey:key];
}

- (void)removeThreadInfoObjectForKey:(id)key
{
    [_listeningSocketThread.threadDictionary removeObjectForKey:key];
}

- (void)removeRequest:(FCGIRequest*)request
{
    NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", request.requestId, request.socket.connectedPort];
    [_currentRequests removeObjectForKey:globalRequestId];
}

- (NSString *)routeLookupURIForRequest:(FKHTTPRequest *)request
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString* returnURI = nil;
    if ( [_delegate respondsToSelector:@selector(routeLookupURIForRequest:)] ) {
        returnURI = [_delegate routeLookupURIForRequest:request];
    }
    if ( returnURI == nil ) {
        returnURI = request.serverVars[@"DOCUMENT_URI"];
    }
    return returnURI;
}

- (FKViewController *)instantiateViewControllerForRoute:(FKRoute *)route userInfo:(NSDictionary*)userInfo
{
    NSString* nibName = route.nibName == nil ? [NSStringFromClass(route.controllerClass) stringByReplacingOccurrencesOfString:@"Controller" withString:@""] : route.nibName;
	
	NSMutableDictionary* combinedUserInfo = [NSMutableDictionary dictionary];
	
	if ( userInfo ) {
		[combinedUserInfo addEntriesFromDictionary:userInfo];
	}
	
	if ( route.userInfo ){
		[combinedUserInfo addEntriesFromDictionary:route.userInfo];
	}
	
    FKViewController* controller = [[route.controllerClass alloc] initWithNibName:nibName bundle:[NSBundle mainBundle] userInfo:combinedUserInfo];
	
    return controller;
}

#pragma mark - AsyncSocket delegate

//- (BOOL)onSocketWillConnect:(AsyncSocket *)sock
//{
////    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
//    return _connectedSockets.count - 1 < _maxConnections;
//}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    [_connectedSockets addObject:newSocket];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    //    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    [sock readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    if (tag == FCGIRecordAwaitingHeaderTag) {
        FCGIRecord* record = [FCGIRecord recordWithHeaderData:data];
        if (record.contentLength == 0) {
            [self handleRecord:record fromSocket:sock];
        } else {
            [self setThreadInfoObject:record forKey:[NSString stringWithFormat:@"%lu", (unsigned long)sock.hash]];
            [sock readDataToLength:record.contentLength+record.paddingLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingContentAndPaddingTag];
        }
    } else if (tag == FCGIRecordAwaitingContentAndPaddingTag) {
        FCGIRecord* record = [self threadInfoObjectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)sock.hash]];
        [record processContentData:data];
        [self handleRecord:record fromSocket:sock];
    }
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] initWithDictionary:err.userInfo];
    if ( userInfo[FKErrorLineKey] == nil ) {
        userInfo[FKErrorLineKey] = @__LINE__;
    }
    if ( userInfo[FKErrorFileKey] == nil ) {
        userInfo[FKErrorFileKey] = @__FILE__;
    }
    NSError* error = [NSError errorWithDomain:err.domain code:err.code userInfo:userInfo];
    [FKApp presentError:error];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [[[[NSThread currentThread] threadDictionary] objectForKey:FCGIKitRequestKey] className]);
    [self removeThreadInfoObjectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)sock.hash]];
    [_connectedSockets removeObject:sock];
    sock = nil;
}

@end

@implementation FKApplication

@synthesize maxConnections = _maxConnections;
@synthesize socketPath = _socketPath;
@synthesize portNumber = _portNumber;
@synthesize listeningInterface = _listenIngInterface;
@synthesize isListeningOnUnixSocket = _isListeningOnUnixSocket;
@synthesize isListeningOnAllInterfaces = _isListeningOnAllInterfaces;
@synthesize isRunning = _isRunning;
@synthesize requestIDs = _requestIDs;
@synthesize listenSocket = _listenSocket;
@synthesize connectedSockets = _connectedSockets;
@synthesize currentRequests = _currentRequests;
@synthesize startupArguments = _startupArguments;
@synthesize listeningSocketThread = _listeningSocketThread;
@synthesize viewControllers = _viewControllers;

- (NSDictionary*)infoDictionary {
    return [[NSBundle mainBundle] infoDictionary];
}

- (id<FKApplicationDelegate>) delegate
{
    return _delegate;
}

- (void)setDelegate:(id<FKApplicationDelegate>)delegate
{
    if ( _delegate ) {
        [[NSNotificationCenter defaultCenter] removeObserver:_delegate];
        _delegate = nil;
    }
    
    _delegate = delegate;
    
    if ( _delegate && [_delegate respondsToSelector:@selector(applicationWillFinishLaunching:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationWillFinishLaunching:) name:FKApplicationWillFinishLaunchingNotification object:nil];
    }
    if ( _delegate && [_delegate respondsToSelector:@selector(applicationDidFinishLaunching:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationDidFinishLaunching:) name:FKApplicationDidFinishLaunchingNotification object:nil];
    }
    if ( _delegate && [_delegate respondsToSelector:@selector(applicationWillTerminate:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationWillTerminate:) name:FKApplicationWillTerminateNotification object:nil];
    }
}

+ (FKApplication *)sharedApplication
{
    if (!FKApp) {
        FKApp = [[FKApplication alloc] init];
    }
    return FKApp;
}

- (id)init {
    self = [super init];
    if ( self != nil ) {
        _isRunning = NO;
        _maxConnections = FKDefaultMaxConnections;
        _isListeningOnUnixSocket = YES;
        _isListeningOnAllInterfaces = YES;
        _socketPath = FKDefaultSocketPath;
        _portNumber = FKDefaultPortNumber;
        _listenIngInterface = [NSString string];
        _startupArguments = [NSArray array];
    }
    return self;
}

- initWithArguments:(const char **)argv count:(int)argc
{
    self = [self init];
    if ( self != nil ) {
        NSMutableArray* args = [[NSMutableArray alloc] initWithCapacity:argc];
        for ( int i = 0; i < argc; i++ ) {
            NSString* arg = [[NSString alloc] initWithCString:argv[i] encoding:[NSString defaultCStringEncoding]];
            [args addObject:arg];
        }
        _startupArguments = args.copy;
    }
    return self;
}

- (void)terminate:(id)sender
{
    // Stop the main run loop
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    FKApplicationTerminateReply reply = FKTerminateNow;
    
    if ( _delegate && [_delegate respondsToSelector:@selector(applicationShouldTerminate:)]) {
        reply = [_delegate applicationShouldTerminate:self];
    }
    
    switch ( reply ) {
        case FKTerminateCancel:
            [self cancelTermination];
            break;
            
        case FKTerminateLater:
            isWaitingOnTerminateLaterReply = YES;          
            waitingOnTerminateLaterReplyTimer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(waitingOnTerminateLaterReplyTimerCallback) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:waitingOnTerminateLaterReplyTimer forMode:FKApplicationRunLoopMode];
            while (isWaitingOnTerminateLaterReply && [[NSRunLoop mainRunLoop] runMode:FKApplicationRunLoopMode beforeDate:[NSDate distantFuture]]) {
            }
            break;
            
        case FKTerminateNow:
        default:
            [self quit];
            break;
    }

}

- (void)waitingOnTerminateLaterReplyTimerCallback
{
}

- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate
{
    isWaitingOnTerminateLaterReply = NO;
    [waitingOnTerminateLaterReplyTimer invalidate];
    
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    if ( shouldTerminate ) {        
        [self quit];
    } else {
        [self cancelTermination];
    }
}

- (void)run
{
    // Finish launch
    [self finishLaunching];
    
    // Run the loop
    [self startRunLoop];

    // quit
    [self terminate:nil];
}

- (void)stop:(id)sender
{
    [self performSelector:@selector(stopCurrentRunLoop) onThread:self.listeningSocketThread withObject:nil waitUntilDone:YES modes:@[FKApplicationRunLoopMode]];
    shouldKeepRunning = NO;
    CFRunLoopStop([[NSRunLoop mainRunLoop] getCFRunLoop]);
}

- (void)presentError:(NSError *)error
{
    if ( self.delegate && [self.delegate respondsToSelector:@selector(application:willPresentError:)] ) {
        error = [self.delegate application:self willPresentError:error];
    }    
    NSLog(@"%@ in %@ on line %@", error.localizedDescription, [error.userInfo valueForKey:FKErrorFileKey], [error.userInfo valueForKey:FKErrorFileKey] );
}

- (void)writeDataToStderr:(NSDictionary *)info
{
    FCGIRequest* request = [info objectForKey:FKRequestKey];
    NSData* data = [info objectForKey:FKDataKey];
    [request writeDataToStderr:data];
}

- (void)writeDataToStdout:(NSDictionary *)info
{
    FCGIRequest* request = [info objectForKey:FKRequestKey];
    NSData* data = [info objectForKey:FKDataKey];
    [request writeDataToStdout:data];
}

- (void)finishRequest:(FCGIRequest*)request
{
    [request doneWithProtocolStatus:FCGI_REQUEST_COMPLETE applicationStatus:0];
    [self removeRequest:request];
}

- (void)finishRequestWithError:(NSDictionary*)userInfo
{
    FKHTTPResponse* httpResponse  = userInfo[FKResponseKey];
    NSError* error = userInfo[FKErrorKey];
    [self presentError:error];
    [httpResponse setHTTPStatus:500];
    [httpResponse finish];
}

-(void)performBackgroundSelector:(SEL)aSelector onTarget:(id)target userInfo:(NSDictionary *)userInfo didEndSelector:(SEL)didEndSelector
{
    FKBackgroundThread* workerThread = [[FKBackgroundThread alloc] initWithTarget:target selector:aSelector userInfo:userInfo didEndSelector:didEndSelector];
    [workerThread start];
}

- (void)performBackgroundDidEndSelector:(SEL)didEndSelector onTarget:(id)target userInfo:(NSDictionary *)userInfo
{
    NSArray* argsArray = @[ NSStringFromSelector(didEndSelector), target, userInfo ];
    [self performSelector:@selector(callBackgroundDidEndSelector:) onThread:self.listeningSocketThread withObject:argsArray waitUntilDone:NO modes:@[FKApplicationRunLoopMode]];
}

- (void)performBackgroundOperation:(FKAppBackgroundOperationBlock)block withCompletion:(FKAppBackgroundOperationCompletionBlock)completion userInfo:(NSDictionary *)userInfo
{
	FKBackgroundThread* workerThread = [[FKBackgroundThread alloc] initWithWorkerBlock:block completion:completion userInfo:userInfo];
	[workerThread start];
}

- (NSString *)temporaryDirectoryLocation
{
    NSString* identifier = [[NSBundle mainBundle] bundleIdentifier] != nil ? [[NSBundle mainBundle] bundleIdentifier] : [self.startupArguments[0] lastPathComponent];
    NSString* tmpDirName =[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), identifier];
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ( ! [fm fileExistsAtPath:tmpDirName isDirectory:&isDir] ) {
        BOOL ok = [fm createDirectoryAtPath:tmpDirName withIntermediateDirectories:NO attributes:nil error:nil];
        if ( ! ok ) {
            return [tmpDirName stringByDeletingLastPathComponent];
        }
    } else if( !isDir ){
        [fm removeItemAtPath:tmpDirName error:nil];
        BOOL ok = [fm createDirectoryAtPath:tmpDirName withIntermediateDirectories:NO attributes:nil error:nil];
        if ( ! ok ) {
            return [tmpDirName stringByDeletingLastPathComponent];
        }
    } else {
        if ( ! [fm isWritableFileAtPath:tmpDirName] ) {
            return [tmpDirName stringByDeletingLastPathComponent];
        }
    }
    return tmpDirName;
}

- (NSDictionary*)dumpConfig
{
    NSDictionary* config = @{FKMaxConnectionsKey: [NSNumber numberWithInteger:self.maxConnections],
                             FKConnectionInfoSocketKey: self.socketPath,
                             FKConnectionInfoInterfaceKey: self.listeningInterface,
                             FKConnectionInfoPortKey: [NSNumber numberWithInteger:self.portNumber],
                             FKConnectionInfoKey: self.isListeningOnUnixSocket ? FKConnectionInfoSocketKey : FKConnectionInfoPortKey,
                             };
    return config;
}

@end