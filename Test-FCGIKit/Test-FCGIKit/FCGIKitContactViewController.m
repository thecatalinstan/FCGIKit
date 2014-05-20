//
//  FCGIKitContactViewController.m
//  Test-FCGIKit
//
//  Created by Cătălin Stan on 5/20/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitContactViewController.h"
#import <libfcgikit.h>

@implementation FCGIKitContactViewController

- (void)viewDidLoad
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    [super viewDidLoad];
}

- (void)didFinishLoading
{
    NSString *name, *email, *message;
    BOOL isPost = [self.request.serverVars[@"REQUEST_METHOD"] isEqualToString:@"POST"];
    if ( isPost ) {
        name = self.request.postVars[@"name"];
        email = self.request.postVars[@"email"];
        message = self.request.postVars[@"message"];
    } else {
        name = @"";
        email = @"";
        message = @"";
    }
    
    [self setObject:[NSNumber numberWithBool:isPost] forVariableNamed:@"isPost"];
    [self setObject:name forVariableNamed:@"name"];
    [self setObject:email forVariableNamed:@"email"];
    [self setObject:message forVariableNamed:@"message"];
}
    
@end
