//
//  FCGIApplication.m
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "GCDAsyncSocket.h"
#import "FCGIKit.h"

#import "FKApplication.h"
#import "FCGIRecord.h"
#import "FCGIBeginRequestRecord.h"
#import "FCGIParamsRecord.h"
#import "FCGIByteStreamRecord.h"
#import "FCGIRequest.h"
#import "FKHTTPRequest.h"
#import "FKHTTPResponse.h"
#import "FKRoute.h"
#import "FKRoutingCenter.h"
#import "FKNib.h"
#import "FKView.h"
#import "FKViewController.h"


NSString* const FCGIKit = @"FCGIKit";
NSString* const FKApplicationRunLoopMode = @"NSDefaultRunLoopMode";

NSString* const FKErrorKey = @"FKError";
NSString* const FKErrorFileKey = @"FKErrorFile";
NSString* const FKErrorLineKey = @"FKErrorLine";
NSString* const FKErrorDomain = @"FKErrorDomain";

NSString* const FKConnectionInfoKey = @"FKConnectionInfo";
NSString* const FKConnectionInfoPortKey = @"FKConnectionInfoPort";
NSString* const FKConnectionInfoInterfaceKey = @"FKConnectionInfoInterface";

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

FKApplication* FKApp;

void handleSIGTERM(int signum) {
    [FKApp performSelectorOnMainThread:@selector(terminate:) withObject:nil waitUntilDone:YES];
}

int FKApplicationMain(int argc, const char **argv, id<FKApplicationDelegate> delegate)
{
    (void)signal(SIGTERM, handleSIGTERM) ;
    FKApplication* app = [[FKApplication alloc] initWithArguments:argv count:argc];
    [app setDelegate:delegate];
    [app run];
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

@implementation FKApplication 

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
	Class class;
	if( ! FKApp ) {
		if( ! ( class = [NSBundle mainBundle].principalClass ) ) {
			NSLog(@"Main bundle does not define an existing principal class: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPrincipalClass"]);
			class = self;
		}
		if( ! [class isSubclassOfClass:self.class] ) {
			NSLog(@"Principal class (%@) of main bundle is not subclass of %@", NSStringFromClass(class), NSStringFromClass(self.class) );
		}
		[class new];
	}

	return FKApp;
}

- (instancetype)init {
    self = [super init];
    if ( self != nil ) {
		FKApp = self;
        _isRunning = NO;
        _isListeningOnAllInterfaces = YES;
        _portNumber = FKDefaultPortNumber;
        _listenIngInterface = [NSString string];
        _startupArguments = [NSArray array];
    }
    return self;
}

- (instancetype) initWithArguments:(const char **)argv count:(int)argc
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
    [self finishLaunching];
    [self startRunLoop];
    [self terminate:nil];
}

- (void)stop:(id)sender
{
    CFRunLoopStop([[NSRunLoop mainRunLoop] getCFRunLoop]);
}

- (void)presentError:(NSError *)error
{
    if ( self.delegate && [self.delegate respondsToSelector:@selector(application:willPresentError:)] ) {
        error = [self.delegate application:self willPresentError:error];
    }
}

- (void)writeDataToStderr:(NSDictionary *)info
{
    FCGIRequest* request = info[FKRequestKey];
    NSData* data = info[FKDataKey];
    [request writeDataToStderr:data];
}

- (void)writeDataToStdout:(NSDictionary *)info
{
    FCGIRequest* request = info[FKRequestKey];
    NSData* data = info[FKDataKey];
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
    NSDictionary* config = @{
                             FKConnectionInfoInterfaceKey: self.listeningInterface,
                             FKConnectionInfoPortKey: @(self.portNumber),
                             FKConnectionInfoKey: FKConnectionInfoPortKey,
                             };
    return config;
}


- (void)quit
{
	[self stopListening];
	
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
	
	listening = [self.listenSocket acceptOnInterface:_isListeningOnAllInterfaces ? nil : _listenIngInterface port:_portNumber error:&error];
	
	
	if ( !listening ) {
		[self presentError:error];
		[self terminate:self];
	}
	
}

- (void)stopListening
{
	
	[_listenSocket disconnect];
	_listenSocket = nil;
	
	// Stop any client connections
	NSUInteger i;
	for(i = 0; i < [self.connectedSockets count]; i++) {
		[(self.connectedSockets)[i] disconnect];
	}
}

- (void)finishLaunching
{
	if ( [self.infoDictionary.allKeys containsObject:FKConnectionInfoKey] ) {
		
		NSDictionary* connectionInfo = self.infoDictionary[FKConnectionInfoKey];
		NSNumber* connectionInfoPort = connectionInfo[FKConnectionInfoPortKey];
		_portNumber = MIN(INT16_MAX, MAX(0, connectionInfoPort.integerValue)) ;
		
		if ( [[(self.infoDictionary)[FKConnectionInfoKey] allKeys] containsObject:FKConnectionInfoInterfaceKey] ) {
			_listenIngInterface = (self.infoDictionary)[FKConnectionInfoKey][FKConnectionInfoInterfaceKey];
		}
	}
	
	_isListeningOnAllInterfaces = _listenIngInterface.length == 0;
	
	_connectedSockets = [NSMutableArray array];
	_currentRequests = [NSMutableDictionary dictionary];
	_viewControllers = [NSMutableDictionary dictionary];
	
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
	if (mainRunLoopObserver) {
		CFRunLoopRef cfLoop = [runLoop getCFRunLoop];
		CFRunLoopAddObserver(cfLoop, mainRunLoopObserver, kCFRunLoopDefaultMode);
	}
	
	// Let observers know that initialization is complete
	[[NSNotificationCenter defaultCenter] postNotificationName:FKApplicationWillFinishLaunchingNotification object:self];
}

- (void)startRunLoop
{
	_workerQueue = [[NSOperationQueue alloc] init];
	_workerQueue.name = [[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"WorkerQueue"];
	_workerQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
	_workerQueue.qualityOfService = NSQualityOfServiceUserInteractive;
	
	NSString* socketQueueLabel = [[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"SocketQueue"];
	_socketQueue = dispatch_queue_create([socketQueueLabel cStringUsingEncoding:NSASCIIStringEncoding], NULL);
	_listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
	[self startListening];
	
	// All startup is complete, let the delegate know they can do their own init here
	[[NSNotificationCenter defaultCenter] postNotificationName:FKApplicationDidFinishLaunchingNotification object:self];
	
	shouldKeepRunning = YES;
	
	NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
	NSTimeInterval keepAliveInterval = [[NSDate distantFuture] timeIntervalSinceNow];
	[runLoop addTimer:[NSTimer timerWithTimeInterval:keepAliveInterval target:nil selector:@selector(stop) userInfo:nil repeats:YES] forMode:FKApplicationRunLoopMode];
	
	while ( shouldKeepRunning && [runLoop runMode:FKApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
		_isRunning=YES;
	}
	
	_isRunning = NO;
}

- (void)stopCurrentRunLoop
{
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
}

-(void)handleRecord:(FCGIRecord*)record fromSocket:(GCDAsyncSocket *)socket
{
	
	if ([record isKindOfClass:[FCGIBeginRequestRecord class]]) {
		
		FCGIRequest* request = [[FCGIRequest alloc] initWithBeginRequestRecord:(FCGIBeginRequestRecord*)record];
		request.socket = socket;
		NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, socket.connectedPort];
		@synchronized(_currentRequests) {
			_currentRequests[globalRequestId] = request;
		}
		[socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
		
	} else if ([record isKindOfClass:[FCGIParamsRecord class]]) {
		
		NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
		FCGIRequest* request;
		@synchronized(_currentRequests) {
			request = _currentRequests[globalRequestId];
		}
		NSDictionary* params = [(FCGIParamsRecord*)record params];
		if ([params count] > 0) {
			[request.parameters addEntriesFromDictionary:params];
		} else {
			if ( _delegate && [_delegate respondsToSelector:@selector(application:didReceiveRequest:)] ) {
				[_delegate application:self didReceiveRequest:@{FKRequestKey: request}];
			}
		}
		[socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
		
	} else if ([record isKindOfClass:[FCGIByteStreamRecord class]]) {
		
		NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
		FCGIRequest* request;
		@synchronized(_currentRequests) {
			request = _currentRequests[globalRequestId];
		}
		NSData* data = [(FCGIByteStreamRecord*)record data];
		if ( [data length] > 0 ) {
			[request.stdinData appendData:data];
			[socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
		} else {
			FKHTTPRequest* httpRequest = [FKHTTPRequest requestWithFCGIRequest:request];
			FKHTTPResponse* httpResponse = [FKHTTPResponse responseWithHTTPRequest:httpRequest];
			
			NSDictionary* userInfo = @{FKRequestKey: httpRequest, FKResponseKey: httpResponse};
			if ( _delegate && [_delegate respondsToSelector:@selector(application:didPrepareResponse:)] ) {
				[_delegate application:self didPrepareResponse:userInfo];
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
					[_workerQueue addOperationWithBlock:^{
						[_delegate application:self presentViewController:viewController];
					}];
				}
				
			} else if ( _delegate && [_delegate respondsToSelector:@selector(application:didNotFindViewController:)]) {

				[_workerQueue addOperationWithBlock:^{
					[_delegate application:self didNotFindViewController:userInfo];
				}];
				
			} else {
				
				[_workerQueue addOperationWithBlock:^{
					NSString* errorDescription = [NSString stringWithFormat:@"No view controller for request URI: %@", httpRequest.parameters[@"DOCUMENT_URI"]];
					NSError* error = [NSError errorWithDomain:FKErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: errorDescription, FKErrorFileKey: @__FILE__, FKErrorLineKey: @__LINE__}];
					NSMutableDictionary* finishRequestUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
					finishRequestUserInfo[FKErrorKey] = error;
					[self finishRequestWithError:finishRequestUserInfo.copy];
				}];
				
			}
		}
	}
}

- (void)removeRequest:(FCGIRequest*)request
{
	NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", request.requestId, request.socket.connectedPort];
	@synchronized(_currentRequests) {
		[_currentRequests removeObjectForKey:globalRequestId];
	}
}

- (NSString *)routeLookupURIForRequest:(FKHTTPRequest *)request
{
	NSString* returnURI = nil;
	if ( [_delegate respondsToSelector:@selector(routeLookupURIForRequest:)] ) {
		returnURI = [_delegate routeLookupURIForRequest:request];
	}
	if ( returnURI == nil ) {
		returnURI = request.parameters[@"DOCUMENT_URI"];
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

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	NSString* delegateQueueLabel = [[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:[NSString stringWithFormat:@"SocketDelegateQueue-%@", @(newSocket.connectedPort)]];
	dispatch_queue_t acceptedSocketQueue = dispatch_queue_create([delegateQueueLabel cStringUsingEncoding:NSASCIIStringEncoding], NULL);
	[newSocket setDelegateQueue:acceptedSocketQueue];
	
	[_connectedSockets addObject:newSocket];
	
	[newSocket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	if (tag == FCGIRecordAwaitingHeaderTag) {
		FCGIRecord* record = [FCGIRecord recordWithHeaderData:data];
		if (record.contentLength == 0) {
			[self handleRecord:record fromSocket:sock];
		} else {
			dispatch_set_context(sock.delegateQueue, (void *)(CFBridgingRetain(record)));
			[sock readDataToLength:(record.contentLength + record.paddingLength) withTimeout:FCGITimeout tag:FCGIRecordAwaitingContentAndPaddingTag];
		}
	} else if (tag == FCGIRecordAwaitingContentAndPaddingTag) {
		FCGIRecord* record = CFBridgingRelease(dispatch_get_context(sock.delegateQueue));
		[record processContentData:data];
		[self handleRecord:record fromSocket:sock];
	}
}

- (void)socket:(GCDAsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] initWithDictionary:err.userInfo];
	if ( userInfo[FKErrorLineKey] == nil ) {
		userInfo[FKErrorLineKey] = @__LINE__;
	}
	if ( userInfo[FKErrorFileKey] == nil ) {
		userInfo[FKErrorFileKey] = @__FILE__;
	}
	NSString* errorDomain = err.domain == nil ? FKErrorDomain : err.domain;
	NSInteger errorCode = err.code == 0 ? -1 : err.code;
	NSError* error = [NSError errorWithDomain:errorDomain code:errorCode userInfo:userInfo];
	[FKApp presentError:error];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock
{
	[_connectedSockets removeObject:sock];
	sock = nil;
}

@end