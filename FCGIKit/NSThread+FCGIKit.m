//
//  NSThread+FCGIKit.m
//  FCGIKit
//
//  Created by Cătălin Stan on 3/29/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "NSThread+FCGIKit.h"

@implementation NSThread (FCGIKit)

- (NSRunLoop*)runLoop
{
    return [NSRunLoop currentRunLoop];
}

@end
