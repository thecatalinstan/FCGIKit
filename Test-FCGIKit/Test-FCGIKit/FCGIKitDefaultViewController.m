//
//  FCGIKitDefaultViewController.m
//  Test-FCGIKit
//
//  Created by Cătălin Stan on 5/20/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitDefaultViewController.h"

@implementation FCGIKitDefaultViewController

- (void)loadView
{
    [super loadView];
}

- (NSString *)postprocessView
{
    return [NSString stringWithFormat:@"%@<h2>%s</h2><p>Here's a stack trace:</p></h2><pre>%@</pre>", [super postprocessView], __PRETTY_FUNCTION__, [NSThread callStackSymbols]];
}

- (NSString *)presentViewController:(BOOL)writeData
{
    return [super presentViewController:writeData];
}


@end
