//
//  main.m
//  Test-FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#ifdef DEBUG
#ifndef DLog
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif
#else
#ifndef DLog
#define DLog(...)
#endif
#endif

#import <libfcgikit.h>
#import "FCGITest.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        int val = FCGIApplicationMain(argc, argv, [[FCGITest alloc] init]);
        return val;
    }
}

