//
//  StatusViewController.m
//  Status
//
//  Created by Cătălin Stan on 12/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//
#import "StatusViewController.h"
#import <FCGIKit/FCGIKit.h>

@implementation StatusViewController

- (void)viewDidLoad
{
    [self.response setValue:( @"text/html; charset=utf-8" ) forHTTPHeaderField:@"Content-type"];
}

- (NSString *)presentViewController:(BOOL)writeData
{
    NSString* output = [NSString stringWithFormat:@"<h1>FCGIKit Status App</h1><pre>%@</pre>", self.request.serverVars];
    if ( writeData ) {
        [self.response writeString:output];
        
        if ( self.automaticallyFinishesResponse ) {
            [self.response finish];
        }
    }
    return output;
}

- (BOOL)automaticallyFinishesResponse
{
    return YES;
}

@end
