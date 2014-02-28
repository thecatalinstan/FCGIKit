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
    
//    for ( ; *argv != NULL; argv++) {
//        NSLog(@"%s", *argv);
//    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    FCGIApp = [FCGIApplication sharedApplication];
    [FCGIApp setDelegate:delegate];
    [FCGIApp run];
    [pool drain];
    return EXIT_SUCCESS;
}

void handleSIGTERM(int signum) {
    NSLog(@"%@", @"Caught SIGTERM. Terminating.");
//    We are using performSelector so that the RunLoop can schedule the event
    [FCGIApp performSelectorOnMainThread:@selector(terminate:) withObject:nil waitUntilDone:YES];
}

@interface FCGIApplication (Private)
- (void)quit;
- (void)cancelTermination;
- (void)startRunLoop;
- (void)finishLaunching;
@end

@implementation FCGIApplication(Private)

NSUInteger counter = 0;

- (void)quit
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    for ( NSUInteger i = 0; i < _workerThreads.count; i++) {
        [[_workerThreads objectAtIndex:i] cancel];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FCGIKitApplicationWillTerminateNotification object:self];
    CFRunLoopRemoveObserver([[NSRunLoop mainRunLoop] getCFRunLoop], mainRunLoopObserver, kCFRunLoopDefaultMode);
    CFRelease(mainRunLoopObserver);
    
    [inputStreamFileHandle closeFile];
    [inputStreamFileHandle release];
    
    exit(EXIT_SUCCESS);
}

- (void)cancelTermination
{
    NSLog(@"%@", NSStringFromSelector(_cmd));    
    [self startRunLoop];
}

- (void)startRunLoop
{
//    NSLog(@"%@", NSStringFromSelector(_cmd));    
    shouldKeepRunning = YES;

    // All startup is complete, let the delegate know they can do their own init here
    [[NSNotificationCenter defaultCenter] postNotificationName:FCGIKitApplicationDidFinishLaunchingNotification object:self];    
    
    NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
    while ( shouldKeepRunning && [runLoop runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
        _isRunning=YES;
    }
    
    _isRunning = NO;
}

- (void)finishLaunching
{
    // Let observers know that initialization is complete
    [[NSNotificationCenter defaultCenter] postNotificationName:FCGIKitApplicationWillFinishLaunchingNotification object:self];
    
    server = [[FCGIServer alloc] initWithPort:12345];
    
    server.paramsAvailableBlock = ^(FCGIRequest* request) {
        NSLog(@"%@", NSStringFromSelector(_cmd));
    };
    
    server.stdinAvailableBlock = ^(FCGIRequest* request) {
        NSLog(@"%@", NSStringFromSelector(_cmd));
        [request writeDataToStdout:[@"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 8\r\n\r\nTest" dataUsingEncoding:NSASCIIStringEncoding]];
        
        [request writeDataToStdout:[@"Test" dataUsingEncoding:NSASCIIStringEncoding]];
        
        [request doneWithProtocolStatus:FCGI_REQUEST_COMPLETE applicationStatus:0];
    };
}
@end

@implementation FCGIApplication

@synthesize maxConnections = _maxConnections;
@synthesize isRunning = _isRunning;
@synthesize workerThreads = _workerThreads;
@synthesize requestIDs = _requestIDs;
@synthesize environment = _environment;

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
    self = [super init];
    if ( self != nil ) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        _isRunning = NO;
        _maxConnections = FCGIKitDefaultMaxConnections;
        
        // Init variables from (executable) bundle info.plist
        if ( [self.infoDictionary.allKeys containsObject:FCGIKitMaxConnectionsKey] ) {
            _maxConnections = MAX(1, ((NSNumber*) [self.infoDictionary valueForKey:FCGIKitMaxConnectionsKey]).integerValue);
        }
        
        NSError* err;
        [server startWithError:&err];
        NSLog(@"%@", err);

        // Setup the runloop
        NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
        
        // Create a run loop observer and attach it to the run loop.
        CFRunLoopObserverContext  context = {0, self, NULL, NULL, NULL};
        mainRunLoopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &mainRunLoopObserverCallback, &context);
        if (mainRunLoopObserver)
        {
            CFRunLoopRef cfLoop = [runLoop getCFRunLoop];
            CFRunLoopAddObserver(cfLoop, mainRunLoopObserver, kCFRunLoopDefaultMode);
        }
        
        [pool drain];
    }
    return self;
}

- (void)terminate:(id)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
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
            waitingOnTerminateLaterReplyTimer = [[NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(waitingOnTerminateLaterReplyTimerCallback) userInfo:nil repeats:NO] retain];
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
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    isWaitingOnTerminateLaterReply = NO;
    [waitingOnTerminateLaterReplyTimer invalidate];
    [waitingOnTerminateLaterReplyTimer release];
    
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    if ( shouldTerminate ) {        
        [self quit];
    } else {
        [self cancelTermination];
    }
}

- (void)run
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Finish launch
    [self finishLaunching];
    
    // Run the loop
    [self startRunLoop];
    
    [pool drain];
    [self terminate:nil];
}

- (void)stop:(id)sender
{
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

@end