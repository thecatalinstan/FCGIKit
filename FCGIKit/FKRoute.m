//
//  FCGIKitRoute.m
//  FCGIKit
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FKRoute.h"
#import "FKViewController.h"
#import "FCGIKit.h"

@implementation FKRoute

@synthesize requestPath = _requestPath;
@synthesize controllerClass = _controllerClass;
@synthesize nibName = _nibName;
@synthesize userInfo = _userInfo;

- (id)initWithRequestPath:(NSString *)requestPath controllerClass:(Class)controllerClass nibName:(NSString*)nibName userInfo:(NSDictionary *)userInfo
{
    if ( requestPath == nil ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"The request path cannot be nil." userInfo:nil];
        return nil;
    }
    self = [self init];
    if ( self != nil ) {
        _requestPath = requestPath;
        _controllerClass = controllerClass == nil ? [FKViewController class] : controllerClass;
        _nibName = nibName;
        _userInfo = userInfo;
    }
    return self;
}

- (id)initWithInfoDictionary:(NSDictionary *)infoDictionary
{
    NSString* requestPath = [infoDictionary objectForKey:FCGIKitRoutePathKey];
    Class controllerClass = NSClassFromString([infoDictionary objectForKey:FCGIKitRouteControllerKey]);
    NSString* nibName = [infoDictionary objectForKey:FCGIKitRouteNibNameKey];
    NSDictionary* userInfo = [infoDictionary objectForKey:FCGIKitRouteUserInfoKey];
    return [self initWithRequestPath:requestPath controllerClass:controllerClass nibName:nibName userInfo:userInfo];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (Controller: %@, Path: %@, NibName: %@)", super.description, self.controllerClass, self.requestPath, self.nibName];
}

@end