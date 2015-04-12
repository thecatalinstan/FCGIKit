//
//  AppDelegate.m
//  Status
//
//  Created by Cătălin Stan on 10/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//    NSLog(@"%@", @(__PRETTY_FUNCTION__));
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
//    NSLog(@"%@", @(__PRETTY_FUNCTION__));
}

- (void)application:(FKApplication *)application didReceiveRequest:(NSDictionary *)userInfo
{
//    NSLog(@"%@", @(__PRETTY_FUNCTION__));
}

- (void)application:(FKApplication *)application didPrepareResponse:(NSDictionary *)userInfo
{
//    NSLog(@"%@", @(__PRETTY_FUNCTION__));
}

- (void)application:(FKApplication *)application didNotFindViewController:(NSDictionary *)userInfo
{
//    NSLog(@"%@", @(__PRETTY_FUNCTION__));
    
    FKHTTPRequest* request = userInfo[FKRequestKey];
    FKHTTPResponse* response = userInfo[FKResponseKey];
    
    NSString* responseString = [NSString stringWithFormat:@"The URL %@ was not found", request.serverVars[@"REQUEST_URI"]];
    
    [response setHTTPStatus:404];
    [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-type"];
    [response writeString: responseString];
    
    [response finish];
}

- (void)application:(FKApplication *)application presentViewController:(FKViewController *)viewController
{
    [viewController presentViewController:YES];
}

@end
