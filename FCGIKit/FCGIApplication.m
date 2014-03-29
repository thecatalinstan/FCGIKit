//
//  FCGIApplication.m
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIApplication.h"

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
- (NSThread*)nextAvailableThread;

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
    NSError *error = nil;
    if(![self.listenSocket acceptOnPort:_portNumber error:&error]) {
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
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Init variables from (executable) bundle info.plist
    if ( [self.infoDictionary.allKeys containsObject:FCGIKitMaxConnectionsKey] ) {
        _maxConnections = MAX(1, ((NSNumber*) [self.infoDictionary valueForKey:FCGIKitMaxConnectionsKey]).integerValue);
    }
    
    if ( [self.infoDictionary.allKeys containsObject:FCGIKitConnectionInfoKey] ) {
        _portNumber = MIN(INT16_MAX, MAX(0, ((NSNumber*) [[self.infoDictionary objectForKey:FCGIKitConnectionInfoKey] valueForKey:FCGIKitConnectionInfoPortKey]).integerValue)) ;
        _socketPath = [[self.infoDictionary objectForKey:FCGIKitConnectionInfoKey] objectForKey:FCGIKitConnectionInfoSocketKey];
    }
    
    _isListeningOnUnixSocket = _portNumber == 0;
    
//    if ( _isListeningOnUnixSocket ) {
//        NSLog(@"Socket: %@", _socketPath);
//    } else {
//        NSLog(@"Port: %lu", (unsigned long)_portNumber);
//    }
    
    NSLog(@"%lu", _maxConnections);
    
    _connectedSockets = [[NSMutableArray alloc] initWithCapacity:_maxConnections];
    _currentRequests = [[NSMutableDictionary alloc] initWithCapacity:_maxConnections];
    
    _workerThreads = [[NSMutableArray alloc] initWithCapacity:_maxConnections];
    for ( NSUInteger i = 0; i < _maxConnections; i++ ) {
        NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(workerThreadMain) object:nil];
        [thread start];
        [_workerThreads addObject:thread];
    }
    NSLog(@"%@", _workerThreads);

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
    
    // Detatch a thread with listening socket
    [self setListeningSocketThread: [[NSThread alloc] initWithTarget:self selector:@selector(listeningThreadMain) object:nil]];
    [self.listeningSocketThread start];
    
    // All startup is complete, let the delegate know they can do their own init here
    [[NSNotificationCenter defaultCenter] postNotificationName:FCGIKitApplicationDidFinishLaunchingNotification object:self];
    
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:600 target:self selector:@selector(ignore:) userInfo:nil repeats:YES] forMode:FCGIKitApplicationRunLoopMode];

    NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
    while ( shouldKeepRunning && [runLoop runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
        _isRunning=YES;
    }
    
    _isRunning = NO;
}

-(void)handleRecord:(FCGIRecord*)record fromSocket:(AsyncSocket *)socket
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    NSLog(@"%@", record);
    
    if ([record isKindOfClass:[FCGIBeginRequestRecord class]]) {
        FCGIRequest* request = [[FCGIRequest alloc] initWithBeginRequestRecord:(FCGIBeginRequestRecord*)record];
        request.socket = socket;
        NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
        @synchronized (_currentRequests) {
            [_currentRequests setObject:request forKey:globalRequestId];
        }
        [socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
    } else if ([record isKindOfClass:[FCGIParamsRecord class]]) {
        NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
        FCGIRequest* request;
        @synchronized (_currentRequests) {
            request = [_currentRequests objectForKey:globalRequestId];
        }
        NSDictionary* params = [(FCGIParamsRecord*)record params];
        if ([params count] > 0) {
            [request.parameters addEntriesFromDictionary:params];
        } else {
//            NSLog(@"%@", request.parameters);
            if ( _delegate && [_delegate respondsToSelector:@selector(applicationDidReceiveRequestParameters:)] ) {
                [_delegate applicationDidReceiveRequestParameters:request];
            }
        }
        [socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
    } else if ([record isKindOfClass:[FCGIByteStreamRecord class]]) {
        NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
        FCGIRequest* request;
        @synchronized (_currentRequests) {
            request = [_currentRequests objectForKey:globalRequestId];
        }
        [request.stdinData appendData:[(FCGIByteStreamRecord*)record data]];
        if ( _delegate && [_delegate respondsToSelector:@selector(applicationDidReceiveRequest:)] ) {
            [_delegate applicationDidReceiveRequest:request];
        }
        @synchronized([[NSThread currentThread] threadDictionary]) {
            [[[NSThread currentThread] threadDictionary] removeObjectForKey:@"socket"];
        }
        [socket disconnectAfterWriting];
        @synchronized (_currentRequests) {
            [_currentRequests removeObjectForKey:globalRequestId];
        }
    }
}

- (NSThread*)nextAvailableThread
{
    NSIndexSet* availableThreads = [self.workerThreads indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ![[[obj threadDictionary] allKeys] containsObject:@"socket"];
    }];
//    return [self.workerThreads objectAtIndex: arc4random() % (self.workerThreads.count - 1) ];
    return [self.workerThreads objectAtIndex:availableThreads.firstIndex];
}

- (void)listeningThreadMain
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    NSLog(@"%@", [NSThread currentThread]);
    // Start the socket
    _listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
    [_listenSocket setRunLoopModes:[NSArray arrayWithObject:FCGIKitApplicationRunLoopMode]];
//    [self performSelector:@selector(startListening) onThread:[NSThread currentThread] withObject:nil waitUntilDone:YES];
    [self startListening];
    
    while ( [[NSRunLoop currentRunLoop] runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
//        NSLog(@"* Processed event. %@", [NSThread currentThread]);
    }
    
    [_listenSocket disconnectAfterReadingAndWriting];
    
    NSLog(@"Exited: %@", [NSThread currentThread]);
}

- (void)workerThreadMain
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSRunLoop currentRunLoop] addTimer:[NSTimer timerWithTimeInterval:DBL_MAX target:self selector:@selector(ignore:) userInfo:nil repeats:YES] forMode:FCGIKitApplicationRunLoopMode];
    while ( [[NSRunLoop currentRunLoop] runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
//        NSLog(@"* Processed event. %@", [NSThread currentThread]);
    }
    NSLog(@"Exited: %s", __PRETTY_FUNCTION__);
}


@end

@implementation FCGIApplication

@synthesize maxConnections = _maxConnections;
@synthesize socketPath = _socketPath;
@synthesize portNumber = _portNumber;
@synthesize isListeningOnUnixSocket = _isListeningOnUnixSocket;
@synthesize isRunning = _isRunning;
@synthesize workerThreads = _workerThreads;
@synthesize requestIDs = _requestIDs;
@synthesize environment = _environment;
@synthesize listenSocket = _listenSocket;
@synthesize connectedSockets = _connectedSockets;
@synthesize currentRequests = _currentRequests;
@synthesize listeningSocketThread = _listeningSocketThread;

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
        _socketPath = FCGIKitDefaultSocketPath;
        _portNumber = FCGIKitDefaultPortNumber;
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

#pragma mark -
#pragma mark AsyncSocket delegate

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
}

- (NSRunLoop *)onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSThread* thread = [self nextAvailableThread];
    @synchronized(thread.threadDictionary) {
        [thread.threadDictionary setObject: newSocket forKey: @"socket"];
    }
    return [thread runLoop];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
//    NSLog(@"%@: %hhd", [NSThread currentThread], [NSThread isMainThread]);
    @synchronized(_connectedSockets) {
		[_connectedSockets addObject:sock];
	}
    [sock readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    NSLog(@"%@: %hhd", [NSThread currentThread], [NSThread isMainThread]);
    if (tag == FCGIRecordAwaitingHeaderTag) {
        FCGIRecord* record = [FCGIRecord recordWithHeaderData:data];
        if (record.contentLength == 0) {
            [self handleRecord:record fromSocket:sock];
        } else {
            [[[NSThread currentThread] threadDictionary] setObject:record forKey:FCGIKitRecordKey];
            [sock readDataToLength:record.contentLength+record.paddingLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingContentAndPaddingTag];
        }
    } else if (tag == FCGIRecordAwaitingContentAndPaddingTag) {
        FCGIRecord* record = [[[NSThread currentThread] threadDictionary] objectForKey:FCGIKitRecordKey];
        [record processContentData:data];
        [self handleRecord:record fromSocket:sock];
    }
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    @synchronized(_connectedSockets) {
        [_connectedSockets removeObject:sock];
    }
}

@end