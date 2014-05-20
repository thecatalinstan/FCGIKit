//
//  main.m
//  Test-FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import <libfcgikit.h>
#import "FCGITest.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        return FCGIApplicationMain(argc, argv, [[FCGITest alloc] init]);
    }
}

