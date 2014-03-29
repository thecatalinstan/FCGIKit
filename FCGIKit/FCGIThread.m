//
//  FCGIThread.m
//  FCGIKit
//
//  Created by Cătălin Stan on 4/27/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "FCGIThread.h"


@interface FCGIThread (Private)

@end

@implementation FCGIThread (Private)

- (void)stop
{
    _isCancelled = YES;
}

@end

@implementation FCGIThread

- (NSRunLoop *)runLoop
{
    return [NSRunLoop currentRunLoop];
}

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
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [[NSRunLoop currentRunLoop] addTimer:[NSTimer timerWithTimeInterval:600 target:self selector:@selector(timerCallback) userInfo:nil repeats:YES] forMode:FCGIKitApplicationRunLoopMode];
    while ( !_isCancelled && [[NSRunLoop currentRunLoop] runMode:FCGIKitApplicationRunLoopMode beforeDate:[NSDate distantFuture]] ) {
        NSLog(@"* Waiting for events %@", self);
        _isCancelled = YES;
        _isExecuting = YES;
    }
    
    _isFinished = YES;
    NSLog(@"Exited: %@", self);
}

- (void)timerCallback
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)cancel
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self performSelector:@selector(stop)];
}

@end