//
//  FCGIApplication.m
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import <objc/message.h>

#import "AsyncSocket.h"
#import "FCGIApplication.h"
#import "FCGIKit.h"
#import "FCGIRecord.h"
#import "FCGIBeginRequestRecord.h"
#import "FCGIParamsRecord.h"
#import "FCGIByteStreamRecord.h"
#import "FCGIRequest.h"
#import "FCGIKitHTTPRequest.h"
#import "FCGIKitHTTPResponse.h"
#import "FCGIKitBackgroundThread.h"

int FCGIApplicationMain(int argc, const char **argv, id<FCGIApplicationDelegate> delegate)
{
    (void)signal(SIGTERM, handleSIGTERM) ;
    FCGIApp = [[FCGIApplication alloc] initWithArguments:argv count:argc];
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

- (void)listeningThreadMain;

- (void)timerCallback;

- (id)threadInfoObjectForKey:(id)key;
- (void)setThreadInfoObject:(id)object forKey:(id)key;
- (void)removeThreadInfoObjectForKey:(id)key;

@end

@implementation FCGIApplication(Private)

- (void)quit
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self performSelector:@selector(stopListening) onThread:self.listeningSocketThread withObject:nil waitUntilDone:YES modes:@[FCGIKitApplicationRunLoopMode]];
    
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
    shouldKeepRunning = YES;
    
    // Detatch a thread for the listening socket
    [self setListeningSocketThread: [[NSThread alloc] initWithTarget:self selector:@selector(listeningThreadMain) object:nil]];
    [self.listeningSocketThread setName:@"FCGIKitListeningThread"];
    [self.listeningSocketThread start];

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
//    NSLog(@"%s %@: %hu", __PRETTY_FUNTION__ record.className, record.contentLength);
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
            if ( _delegate && [_delegate respondsToSelector:@selector(applicationDidReceiveRequest:)] ) {
                [self performSelector:@selector(callDelegateDidReceiveRequest:) onThread:[NSThread currentThread] withObject:request waitUntilDone:NO modes:@[FCGIKitApplicationRunLoopMode]];
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
            if ( _delegate && [_delegate respondsToSelector:@selector(applicationWillSendResponse:)] ) {
                [self performSelector:@selector(callDelegateWillSendResponse:) onThread:[NSThread currentThread] withObject:request waitUntilDone:NO modes:@[FCGIKitApplicationRunLoopMode]];
            }
        }
    }
}

- (void)callDelegateDidReceiveRequest:(FCGIRequest*)request
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    NSDictionary* userInfo = @{FCGIKitRequestKey:request};
    [_delegate applicationDidReceiveRequest:userInfo];
}

- (void)callDelegateWillSendResponse:(FCGIRequest*)request
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    FCGIKitHTTPRequest* httpRequest = [FCGIKitHTTPRequest requestWithFCGIRequest:request];
    FCGIKitHTTPResponse* httpResponse = [FCGIKitHTTPResponse responseWithHTTPRequest:httpRequest];
    NSDictionary* userInfo = @{FCGIKitRequestKey: httpRequest, FCGIKitResponseKey: httpResponse};
    [_delegate applicationWillSendResponse:userInfo];
    NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", request.requestId, request.socket.connectedPort];
    [_currentRequests removeObjectForKey:globalRequestId];
}

- (void)callBackgroundDidEndSelector:(NSArray*)argsArray
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    objc_msgSend(argsArray[1], NSSelectorFromString(argsArray[0]), argsArray[2]);
}

- (void)listeningThreadMain
{
    @autoreleasepool {
        _listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
        [_listenSocket setRunLoopModes:[NSArray arrayWithObject:FCGIKitApplicationRunLoopMode]];
        [self startListening];
        while ( [[NSRunLoop currentRunLoop] runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
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
    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    [FCGIApp presentError:err];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [[[[NSThread currentThread] threadDictionary] objectForKey:FCGIKitRequestKey] className]);
    [self removeThreadInfoObjectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)sock.hash]];
    [_connectedSockets removeObject:sock];
    sock = nil;
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
@synthesize requestIDs = _requestIDs;
@synthesize listenSocket = _listenSocket;
@synthesize connectedSockets = _connectedSockets;
@synthesize currentRequests = _currentRequests;
@synthesize startupArguments = _startupArguments;
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
    return FCGIApp;
}

- (id)init {
    self = [super init];
    if ( self != nil ) {
        _isRunning = NO;
        _maxConnections = FCGIKitDefaultMaxConnections;
        _isListeningOnUnixSocket = YES;
        _isListeningOnAllInterfaces = YES;
        _socketPath = FCGIKitDefaultSocketPath;
        _portNumber = FCGIKitDefaultPortNumber;
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
}

-(void)performBackgroundSelector:(SEL)aSelector onTarget:(id)target userInfo:(NSDictionary *)userInfo didEndSelector:(SEL)didEndSelector
{
//    NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    FCGIKitBackgroundThread* workerThread = [[FCGIKitBackgroundThread alloc] initWithTarget:target selector:aSelector userInfo:userInfo didEndSelector:didEndSelector];
    [workerThread start];
}

- (void)performBackgroundDidEndSelector:(SEL)didEndSelector onTarget:(id)target userInfo:(NSDictionary *)userInfo
{
//    NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    NSArray* argsArray = @[ NSStringFromSelector(didEndSelector), target, userInfo ];
    [self performSelector:@selector(callBackgroundDidEndSelector:) onThread:self.listeningSocketThread withObject:argsArray waitUntilDone:NO modes:@[FCGIKitApplicationRunLoopMode]];
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
    NSDictionary* config = @{FCGIKitMaxConnectionsKey: [NSNumber numberWithInteger:self.maxConnections],
                             FCGIKitConnectionInfoSocketKey: self.socketPath,
                             FCGIKitConnectionInfoInterfaceKey: self.listeningInterface,
                             FCGIKitConnectionInfoPortKey: [NSNumber numberWithInteger:self.portNumber],
                             FCGIKitConnectionInfoKey: self.isListeningOnUnixSocket ? FCGIKitConnectionInfoSocketKey : FCGIKitConnectionInfoPortKey,
                             };
    return config;
}

@end