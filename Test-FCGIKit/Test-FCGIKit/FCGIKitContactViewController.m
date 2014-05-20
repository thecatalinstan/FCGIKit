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
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [super viewDidLoad];
}

- (void)didFinishLoading
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSMutableString* viewText = [NSMutableString stringWithString:self.view.templateText];
    
    [viewText appendFormat:@"<h1>%@</h1>", self];
    [viewText appendFormat:@"<h2>%s</h2><p>Here's a stack trace:</p></h2><pre>%@</pre>", __PRETTY_FUNCTION__, [NSThread callStackSymbols]];
    [viewText appendFormat:@"<h2>GET</h2><pre>%@</pre>", self.request.getVars];
    [viewText appendFormat:@"<h2>POST</h2><pre>%@</pre>", self.request.postVars];
    [viewText appendFormat:@"<h2>FILES</h2><pre>%@</pre>", self.request.files];
    [viewText appendFormat:@"<h2>COOKIE</h2><pre>%@</pre>", self.request.cookieVars];
    [viewText appendFormat:@"<h2>SERVER</h2><pre>%@</pre>", self.request.serverVars];
    
    [self.view setTemplateText:viewText.copy];
}

- (NSString *)postprocessView
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [super postprocessView];
}

@end
