//
//  FCGIApplication.m
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "AsyncSocket.h"
#import "FCGIApplication.h"
#import "FCGIKit.h"
#import "FCGIRecord.h"
#import "FCGIBeginRequestRecord.h"
#import "FCGIParamsRecord.h"
#import "FCGIByteStreamRecord.h"
#import "FCGIRequest.h"
#import "FCGIThread.h"
#import "FCGIKitHTTPRequest.h"
#import "FCGIKitHTTPResponse.h"

int FCGIApplicationMain(int argc, const char **argv, id<FCGIApplicationDelegate> delegate)
{
    (void)signal(SIGTERM, handleSIGTERM) ;
    FCGIApp = [FCGIApplication sharedApplication];
    [FCGIApp setDelegate:delegate];
    [FCGIApp run];
    return EXIT_SUCCESS;
}

void handleSIGTERM(int signum) {
//    NSLog(@"%@", @"Caught SIGTERM. Terminating.");
    [FCGIApp performSelectorOnMainThread:@selector(terminate:) withObject:nil waitUntilDone:YES];
}

@interface FCGIApplication (Private)
- (void)quit;
- (void)cancelTermination;
- (void)startRunLoop;
- (void)finishLaunching;

- (void)startListening;
- (void)stopListening;

- (void)handleRecord:(FCGIRecord*)record fromSocket:(AsyncSocket*)socket;
- (NSThread*)nextAvailableThread:(FCGIRequest*)request;
- (NSThread *)newWorkerThread:(FCGIRequest*)request;

- (void)listeningThreadMain;
- (void)workerThreadMain;

- (void)timerCallback;

- (id)threadInfoObjectForKey:(id)key;
- (void)setThreadInfoObject:(id)object forKey:(id)key;
- (void)removeThreadInfoObjectForKey:(id)key;

- (NSThread*)workerThreadForRequest:(FCGIRequest*)request;
- (void)setWorkerThread:(NSThread*)thread forRequest:(FCGIRequest*)request;
- (void)removeWorkerThreadForRequest:(FCGIRequest*)request;

@end

@implementation FCGIApplication(Private)

- (void)quit
{
//    NSLog(@"%@", NSStringFromSelector(_cmd));

    [self stopListening];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FCGIKitApplicationWillTerminateNotification object:self];
    CFRunLoopRemoveObserver([[NSRunLoop mainRunLoop] getCFRunLoop], mainRunLoopObserver, kCFRunLoopDefaultMode);
    CFRelease(mainRunLoopObserver);

    exit(EXIT_SUCCESS);
}

- (void)cancelTermination
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self startRunLoop];
}

- (void)startListening
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSError *error;
    BOOL listening = NO;
    if ( self.isListeningOnAllInterfaces ) {
        listening = [self.listenSocket acceptOnPort:_portNumber error:&error];
    } else {
        listening = [self.listenSocket acceptOnInterface:_listenIngInterface port:_portNumber error:&error];
    }
    
    if ( !listening ) {
        [self presentError:error];
        [self terminate:self];
    }

}

- (void)stopListening
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.listenSocket disconnect];
    
    // Stop any client connections
    NSUInteger i;
    for(i = 0; i < [self.connectedSockets count]; i++) {
        [[self.connectedSockets objectAtIndex:i] disconnect];
    }
}

- (void)finishLaunching
{
    if ( [self.infoDictionary.allKeys containsObject:FCGIKitMaxConnectionsKey] ) {
        _maxConnections = MAX(1, ((NSNumber*) [self.infoDictionary valueForKey:FCGIKitMaxConnectionsKey]).integerValue);
    }
    
    if ( [self.infoDictionary.allKeys containsObject:FCGIKitMaxThreadsKey] ) {
        _maxThreads = MAX(1, ((NSNumber*) [self.infoDictionary valueForKey:FCGIKitMaxThreadsKey]).integerValue);
    }
    
    if ( [self.infoDictionary.allKeys containsObject:FCGIKitInitialThreadsKey] ) {
        _initialThreads = MIN(_maxThreads, MAX(1, ((NSNumber*) [self.infoDictionary valueForKey:FCGIKitInitialThreadsKey]).integerValue));
    }
    
    if ( [self.infoDictionary.allKeys containsObject:FCGIKitRequestsPerThreadKey] ) {
        _requestsPerThread = MAX(1, ((NSNumber*) [self.infoDictionary valueForKey:FCGIKitRequestsPerThreadKey]).integerValue);
    }
    
    if ( [self.infoDictionary.allKeys containsObject:FCGIKitConnectionInfoKey] ) {
        _portNumber = MIN(INT16_MAX, MAX(0, ((NSNumber*) [[self.infoDictionary objectForKey:FCGIKitConnectionInfoKey] valueForKey:FCGIKitConnectionInfoPortKey]).integerValue)) ;
        
        if ( [[[self.infoDictionary objectForKey:FCGIKitConnectionInfoKey] allKeys] containsObject:FCGIKitConnectionInfoInterfaceKey] ) {
            _listenIngInterface = [[self.infoDictionary objectForKey:FCGIKitConnectionInfoKey] objectForKey:FCGIKitConnectionInfoInterfaceKey];
        }
        
        _socketPath = [[self.infoDictionary objectForKey:FCGIKitConnectionInfoKey] objectForKey:FCGIKitConnectionInfoSocketKey];
    }
    _isListeningOnUnixSocket = _portNumber == 0;
    _isListeningOnAllInterfaces = _listenIngInterface.length == 0;
    
    _connectedSockets = [[NSMutableArray alloc] initWithCapacity:_maxConnections + 1];
    _currentRequests = [[NSMutableDictionary alloc] init];
    _workerThreads = [[NSMutableArray alloc] initWithCapacity:_initialThreads];
    
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
    [[NSNotificationCenter defaultCenter] postNotificationName:FCGIKitApplicationWillFinishLaunchingNotification object:self];
}

- (void)startRunLoop
{
//    NSLog(@"%@", NSStringFromSelector(_cmd));
    shouldKeepRunning = YES;
    
    // Detatch a thread for the listening socket
    [self setListeningSocketThread: [[NSThread alloc] initWithTarget:self selector:@selector(listeningThreadMain) object:nil]];
    [self.listeningSocketThread setName:@"FCGIKitListeningThread"];
    [self.listeningSocketThread start];
    
    // Start the pool of worker threads
    for ( NSUInteger i = 0; i < _initialThreads; i++ ) {
        [_workerThreads addObject:[self newWorkerThread: nil]];
    }
    
    // All startup is complete, let the delegate know they can do their own init here
    [[NSNotificationCenter defaultCenter] postNotificationName:FCGIKitApplicationDidFinishLaunchingNotification object:self];
    
    NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
    [runLoop addTimer:[NSTimer timerWithTimeInterval:DBL_MAX target:self selector:@selector(timerCallback) userInfo:nil repeats:YES] forMode:FCGIKitApplicationRunLoopMode];
    while ( shouldKeepRunning && [runLoop runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
        _isRunning=YES;
    }
    
    _isRunning = NO;
}

-(void)handleRecord:(FCGIRecord*)record fromSocket:(AsyncSocket *)socket
{
    if ([record isKindOfClass:[FCGIBeginRequestRecord class]]) {
        FCGIRequest* request = [[FCGIRequest alloc] initWithBeginRequestRecord:(FCGIBeginRequestRecord*)record];
        request.socket = socket;
        NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, socket.connectedPort];
        @synchronized(_currentRequests) {
            [_currentRequests setObject:request forKey:globalRequestId];
        }
        [socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
    } else if ([record isKindOfClass:[FCGIParamsRecord class]]) {
        NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
        FCGIRequest* request;
        @synchronized(_currentRequests) {
            request = [_currentRequests objectForKey:globalRequestId];
        }
        NSDictionary* params = [(FCGIParamsRecord*)record params];
        if ([params count] > 0) {
            [request.parameters addEntriesFromDictionary:params];
        } else {
            [self removeThreadInfoObjectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)socket.hash]];
            if ( _delegate && [_delegate respondsToSelector:@selector(applicationDidReceiveRequest:)] ) {
                NSDictionary* userInfo = @{FCGIKitRequestKey:request};
                [_delegate applicationDidReceiveRequest:userInfo];
            }
        }
        [socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
    } else if ([record isKindOfClass:[FCGIByteStreamRecord class]]) {
//        NSLog(@"%@", record);
        NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
        FCGIRequest* request;
        @synchronized(_currentRequests) {
            request = [_currentRequests objectForKey:globalRequestId];
        }
        NSData* data = [(FCGIByteStreamRecord*)record data];

        [request.stdinData appendData:data];
 
//        [request writeDataToStdout:[@"Status: 200\nContent-type: text/plain\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
//        [request writeDataToStdout:data];
//        [request doneWithProtocolStatus:FCGI_REQUEST_COMPLETE applicationStatus:0];
    
        if ( _delegate && [_delegate respondsToSelector:@selector(applicationWillSendResponse:)] ) {
            NSThread* thread = [self workerThreadForRequest:request];
            [request.socket moveToRunLoop:thread.runLoop];
            [self performSelector:@selector(callDelegateWillSendResponse:) onThread:thread withObject:request waitUntilDone:NO modes:@[FCGIKitApplicationRunLoopMode]];
        }
    }
}

- (void)callDelegateWillSendResponse:(FCGIRequest*)request
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    FCGIKitHTTPRequest* httpRequest = [FCGIKitHTTPRequest requestWithFCGIRequest:request];
    FCGIKitHTTPResponse* httpResponse = [FCGIKitHTTPResponse requestWithHTTPRequest:httpRequest];
    NSDictionary* userInfo = @{FCGIKitRequestKey: httpRequest, FCGIKitResponseKey: httpResponse};
    [_delegate applicationWillSendResponse:userInfo];
}

- (NSThread*)nextAvailableThread:(FCGIRequest*)request
{
    @synchronized(_workerThreads) {    
        NSThread* thread;
        // Get the free threads
        NSPredicate* freeThreadsPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            NSThread* t = evaluatedObject;
            return [t.threadDictionary.allKeys containsObject:FCGIKitRequestKey] && [t.threadDictionary objectForKey:FCGIKitRequestKey] != nil && [[t.threadDictionary objectForKey:FCGIKitRequestKey] count] == 0;
        }];
        NSArray* freeThreads = [_workerThreads filteredArrayUsingPredicate: freeThreadsPredicate ];
        
        if ( freeThreads.count == 0 ) {
            if ( _workerThreads.count < _maxThreads ) {
                thread = [self newWorkerThread:request];
                [_workerThreads addObject:thread];
            } else {
                NSArray* availableThreads = [_workerThreads sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    NSUInteger count1 = [[[obj1 threadDictionary] objectForKey:FCGIKitRequestKey] count];
                    NSUInteger count2 = [[[obj2 threadDictionary] objectForKey:FCGIKitRequestKey] count];
                    return [[NSNumber numberWithInteger:count1] compare:[NSNumber numberWithInteger:count2]];
                }];
                thread = [availableThreads firstObject];
                if ( [[thread.threadDictionary objectForKey:FCGIKitRequestKey] count] == _requestsPerThread ) {
                    [request doneWithProtocolStatus:FCGI_OVERLOADED applicationStatus:-1];
                    return nil;
                }
            }
        
        } else {
            thread = [freeThreads firstObject];
        }
        
        [self setWorkerThread:thread forRequest:request];
        return thread;
    }
}

- (NSThread *)newWorkerThread:(FCGIRequest*)request
{
    NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(workerThreadMain) object:nil];
    [thread setName:[NSString stringWithFormat:@"FCGIKitWorkerThread %lu", _workerThreads.count + 1]];
    [thread.threadDictionary setObject:[NSMutableSet set] forKey:FCGIKitRequestKey];
    [thread start];
    
    if ( request != nil ) {
        [self setWorkerThread:thread forRequest:request];
    }

//    NSLog(@" * New thread: %@", thread);
    
    return thread;
}

- (void)listeningThreadMain
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    _listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
    [_listenSocket setRunLoopModes:[NSArray arrayWithObject:FCGIKitApplicationRunLoopMode]];
    [self startListening];
    while ( [[NSRunLoop currentRunLoop] runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {}
    [self stopListening];
//    NSLog(@"Exited: %@", [NSThread currentThread]);
}

- (void)workerThreadMain
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:[NSTimer timerWithTimeInterval:DBL_MAX target:self selector:@selector(timerCallback) userInfo:nil repeats:YES] forMode:FCGIKitApplicationRunLoopMode];
    while ( [runLoop runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {}
//    NSLog(@"Exited: %s", __PRETTY_FUNCTION__);
}

- (void)timerCallback
{
    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
}

- (id)threadInfoObjectForKey:(id)key
{
    @synchronized(_listeningSocketThread) {
        if ( [_listeningSocketThread.threadDictionary.allKeys containsObject:key] ) {
            return [_listeningSocketThread.threadDictionary objectForKey:key];
        } else {
            return nil;
        }
    }
}

- (void)setThreadInfoObject:(id)object forKey:(id)key
{
    @synchronized(_listeningSocketThread) {
        [_listeningSocketThread.threadDictionary setObject:object forKey:key];
    }
}

- (void)removeThreadInfoObjectForKey:(id)key
{
    @synchronized(_listeningSocketThread) {
        [_listeningSocketThread.threadDictionary removeObjectForKey:key];
    }
}

- (NSThread *)workerThreadForRequest:(FCGIRequest *)request
{
    NSString* key = [NSString stringWithFormat:@"%lu", (unsigned long)request.hash];
    NSThread* thread = [self threadInfoObjectForKey:key];
    if ( thread == nil ) {
        thread = [self nextAvailableThread:request];
    }
    return thread;
}

- (void)setWorkerThread:(NSThread *)thread forRequest:(FCGIRequest *)request
{
    NSString* key = [NSString stringWithFormat:@"%lu", (unsigned long)request.hash];
    [self setThreadInfoObject:thread forKey:key];
    if ( ![thread.threadDictionary.allKeys containsObject:FCGIKitRequestKey] || [thread.threadDictionary objectForKey:FCGIKitRequestKey] == nil ) {
        [thread.threadDictionary setObject:[NSMutableSet set] forKey:FCGIKitRequestKey];
    }
    [[thread.threadDictionary objectForKey:FCGIKitRequestKey] addObject:request];
}

- (void)removeWorkerThreadForRequest:(FCGIRequest *)request
{
    NSString* key = [NSString stringWithFormat:@"%lu", (unsigned long)request.hash];
    NSThread* thread = [self workerThreadForRequest:request];
    [self removeThreadInfoObjectForKey:key];
    if ( [thread.threadDictionary.allKeys containsObject:FCGIKitRequestKey] && [thread.threadDictionary objectForKey:FCGIKitRequestKey] != nil ) {
        [[thread.threadDictionary objectForKey:FCGIKitRequestKey] removeObject:request];
    }
}


#pragma mark -
#pragma mark AsyncSocket delegate

//- (BOOL)onSocketWillConnect:(AsyncSocket *)sock
//{
////    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
//    return _connectedSockets.count - 1 < _maxConnections;
//}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    //    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    [_connectedSockets addObject:sock];
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
    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    NSLog(@"%@", err);
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    //    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    [_connectedSockets removeObject:sock];
    [self removeThreadInfoObjectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)sock.hash]];
}

@end

@implementation FCGIApplication

@synthesize maxConnections = _maxConnections;
@synthesize socketPath = _socketPath;
@synthesize portNumber = _portNumber;
@synthesize listeningInterface = _listenIngInterface;
@synthesize isListeningOnUnixSocket = _isListeningOnUnixSocket;
@synthesize isListeningOnAllInterfaces = _isListeningOnAllInterfaces;
@synthesize isRunning = _isRunning;
@synthesize workerThreads = _workerThreads;
@synthesize requestIDs = _requestIDs;
@synthesize environment = _environment;
@synthesize listenSocket = _listenSocket;
@synthesize connectedSockets = _connectedSockets;
@synthesize currentRequests = _currentRequests;

- (NSThread *)listeningSocketThread
{
    @synchronized(_listeningSocketThread) {
        return _listeningSocketThread;
    }
}

- (void)setListeningSocketThread:(NSThread *)listeningSocketThread
{
    @synchronized(_listeningSocketThread) {
        _listeningSocketThread = listeningSocketThread;
    }
}

- (NSDictionary*)infoDictionary {
    return [[NSBundle mainBundle] infoDictionary];
}

- (id<FCGIApplicationDelegate>) delegate
{
    return _delegate;
}

- (void)setDelegate:(id<FCGIApplicationDelegate>)delegate
{
    if ( _delegate ) {
        [[NSNotificationCenter defaultCenter] removeObserver:_delegate];
        _delegate = nil;
    }
    
    _delegate = delegate;
    
    if ( _delegate && [_delegate respondsToSelector:@selector(applicationWillFinishLaunching:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationWillFinishLaunching:) name:FCGIKitApplicationWillFinishLaunchingNotification object:nil];
    }
    if ( _delegate && [_delegate respondsToSelector:@selector(applicationDidFinishLaunching:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationDidFinishLaunching:) name:FCGIKitApplicationDidFinishLaunchingNotification object:nil];
    }
    if ( _delegate && [_delegate respondsToSelector:@selector(applicationWillTerminate:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationWillTerminate:) name:FCGIKitApplicationWillTerminateNotification object:nil];
    }
}

+ (FCGIApplication *)sharedApplication
{
    if (!FCGIApp) {
        FCGIApp = [[FCGIApplication alloc] init];
    }
    @synchronized (FCGIApp) {
        return FCGIApp;
    }
}

- (id)init {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super init];
    if ( self != nil ) {
        _isRunning = NO;
        _maxConnections = FCGIKitDefaultMaxConnections;
        _isListeningOnUnixSocket = YES;
        _isListeningOnAllInterfaces = YES;
        _socketPath = FCGIKitDefaultSocketPath;
        _portNumber = FCGIKitDefaultPortNumber;
        _listenIngInterface = [NSString string];
        _maxThreads = FCGIKitDefaultMaxThreads;
        _initialThreads = FCGIKitDefaultInitialThreads;
        _requestsPerThread = FCGIKitDefaultRequestsPerThread;
    }
    return self;
}

- (void)terminate:(id)sender
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Stop the main run loop
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    FCGIApplicationTerminateReply reply = FCGITerminateNow;
    
    if ( _delegate && [_delegate respondsToSelector:@selector(applicationShouldTerminate:)]) {
        reply = [_delegate applicationShouldTerminate:self];
    }
    
    switch ( reply ) {
        case FCGITerminateCancel:
            [self cancelTermination];
            break;
            
        case FCGITerminateLater:
            isWaitingOnTerminateLaterReply = YES;          
            waitingOnTerminateLaterReplyTimer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(waitingOnTerminateLaterReplyTimerCallback) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:waitingOnTerminateLaterReplyTimer forMode:FCGIKitApplicationRunLoopMode];
            while (isWaitingOnTerminateLaterReply && [[NSRunLoop mainRunLoop] runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]]) {
            }
            break;
            
        case FCGITerminateNow:
        default:
            [self quit];
            break;
    }

}

- (void)waitingOnTerminateLaterReplyTimerCallback
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
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
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Finish launch
    [self finishLaunching];
    
    // Run the loop
    [self startRunLoop];

    // quit
    [self terminate:nil];
}

- (void)stop:(id)sender
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self stopListening];
    shouldKeepRunning = NO;
    CFRunLoopStop([[NSRunLoop mainRunLoop] getCFRunLoop]);
}

- (void)presentError:(NSError *)error
{
    if ( self.delegate && [self.delegate respondsToSelector:@selector(application:willPresentError:)] ) {
        error = [self.delegate application:self willPresentError:error];
    }    
    NSLog(@"%@ in %@ on line %@", error.localizedDescription, [error.userInfo valueForKey:FCGIKitErrorFileKey], [error.userInfo valueForKey:FCGIKitErrorFileKey] );
}

- (void)writeDataToStderr:(NSDictionary *)info
{
    FCGIRequest* request = [info objectForKey:FCGIKitRequestKey];
    NSData* data = [info objectForKey:FCGIKitDataKey];
    [request writeDataToStderr:data];
}

- (void)writeDataToStdout:(NSDictionary *)info
{
    FCGIRequest* request = [info objectForKey:FCGIKitRequestKey];
    NSData* data = [info objectForKey:FCGIKitDataKey];
    [request writeDataToStdout:data];
}

- (void)finishRequest:(FCGIRequest*)request
{
    [request doneWithProtocolStatus:FCGI_REQUEST_COMPLETE applicationStatus:0];
    [self removeWorkerThreadForRequest:request];
}


- (NSDictionary*)dumpConfig
{
    NSDictionary* config = @{FCGIKitMaxConnectionsKey: [NSNumber numberWithInteger:self.maxConnections],
                             FCGIKitMaxThreadsKey: [NSNumber numberWithInteger:self.maxThreads],
                             FCGIKitInitialThreadsKey: [NSNumber numberWithInteger:self.initialThreads],
                             FCGIKitRequestsPerThreadKey: [NSNumber numberWithInteger:self.requestsPerThread],
                             FCGIKitConnectionInfoSocketKey: self.socketPath,
                             FCGIKitConnectionInfoPortKey: [NSNumber numberWithInteger:self.portNumber],
                             FCGIKitConnectionInfoKey: self.isListeningOnUnixSocket ? FCGIKitConnectionInfoSocketKey : FCGIKitConnectionInfoPortKey,
                             };
    return config;
}


@end