//
//  FCGIThread.m
//  FCGIKit
//
//  Created by Cătălin Stan on 4/27/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIThread.h"


@interface FCGIThread (Private)

- (void)didAcceptConnection:(NSNotification*)notification;
- (void)processSocketData:(NSNotification*)notification;

@end

@implementation FCGIThread (Private)

- (void)stop
{
    _isCancelled = YES;
}

- (void)didAcceptConnection:(NSNotification*)notification
{
    _isExecuting = YES;
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    NSDictionary* userInfo = [notification userInfo];
    NSFileHandle* remoteFileHandle = [userInfo objectForKey:NSFileHandleNotificationFileHandleItem];
    
    if([[userInfo allKeys] containsObject:@"NSFileHandleError"]){
        NSNumber* errorNo = [userInfo objectForKey:@"NSFileHandleError"];
        if( errorNo ) {
            // TODO: present a proper error
            NSLog(@"NSFileHandle Error: %@", errorNo);
            return;
        }
    }
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(processSocketData:) name: NSFileHandleReadCompletionNotification object:remoteFileHandle];
    [remoteFileHandle readInBackgroundAndNotify];    
}

- (void)processSocketData:(NSNotification*)notification
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
//    NSLog(@"%@", notification);
    
    NSData* requestData = [notification.userInfo objectForKey:NSFileHandleNotificationDataItem];
//    NSLog(@"%@", [[NSString alloc]initWithData:requestData encoding:NSUTF8StringEncoding]);
    
    NSLog(@"Length: %ld", (unsigned long)requestData.length);
    
    unsigned char hdrBuf[8];
    NSUInteger version;
    NSUInteger type;
    NSUInteger requestID;       // 2 bytes
    NSUInteger contentLength;   // 2 bytes
    NSUInteger paddingLength;
    
    NSUInteger offset = 0;
    while ( offset < requestData.length - 8) {
        [requestData getBytes:&hdrBuf range:NSMakeRange(offset, 8)];
        
        version = hdrBuf[0] & 0xFF;
        type = hdrBuf[1] & 0xFF;
        requestID = ((hdrBuf[2] & 0xFF) << 8) | (hdrBuf[3] & 0xFF);
        contentLength = ((hdrBuf[4] & 0xFF) << 8) | (hdrBuf[5] & 0xFF);
        paddingLength = hdrBuf[6] & 0xFF;
    
        NSLog(@"version: %lu, type: %lu, requestId: %lu, contentLength: %lu, paddingLength: %lu", (unsigned long)version, (unsigned long)type, (unsigned long)requestID, (unsigned long)contentLength, (unsigned long)paddingLength);
        
        offset += 7;
        
        unsigned char contentData[contentLength];
        [requestData getBytes:contentData range:NSMakeRange(offset, contentLength)];
        
        NSLog(@"Content-data: %s", contentData);
        offset += contentLength + paddingLength;
    }

    
//    FCGIRecord* record = [[FCGIRecord alloc] initWithData:requestData];
//    NSLog(@"%@", record);
//    [record release];
//    
    _isExecuting = NO;
}
@end

@implementation FCGIThread

- (BOOL)isCancelled
{
    return _isCancelled;
}

- (BOOL)isExecuting
{
    return _isExecuting;
}

- (BOOL)isFinished
{
    return _isFinished;
}

- (id)init
{
    self = [super init];
    if ( self != nil )
    {
        _isCancelled = NO;
        _isExecuting = NO;
        _isFinished = NO;
    }
    return self;
}

- (id)initWithTarget:(id)target selector:(SEL)selector object:(id)argument
{
    self = [super initWithTarget:target selector:selector object:argument];
    if ( self != nil )
    {
        _isCancelled = NO;
        _isExecuting = NO;
        _isFinished = NO;
    }
    return self;
}

- (void)main
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAcceptConnection:) name:NSFileHandleConnectionAcceptedNotification object:nil];
    [[[NSFileHandle alloc] initWithFileDescriptor:FCGI_LISTENSOCK_FILENO] acceptConnectionInBackgroundAndNotify];    
    
    while ( !_isCancelled && [[NSRunLoop currentRunLoop] runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
        NSLog(@"* Waiting for events %@", self);
    }
    
    _isFinished = YES;
    
    [pool drain];
}

- (void)cancel
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self performSelector:@selector(stop)];
}

@end