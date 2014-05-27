//
//  FCGIKitRoutingCenter.m
//  FCGIKit
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitRoutingCenter.h"
#import "FCGIKit.h"
#import "FCGIKitRoute.h"

@interface FCGIKitRoutingCenter (Private)

- (void)loadRoutes:(NSArray*)routes;

@end

@implementation FCGIKitRoutingCenter (Private)

- (void)loadRoutes:(NSArray*)routesOrNil {
    if ( routesOrNil == nil ) {
        routesOrNil = [[NSBundle mainBundle] objectForInfoDictionaryKey:FCGIKitRoutesKey];
    }
    
    NSMutableDictionary* routesDictionary = [[NSMutableDictionary alloc] initWithCapacity:routesOrNil.count];
    [routesOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        FCGIKitRoute* route = [[FCGIKitRoute alloc] initWithInfoDictionary:obj];
        NSString* key = route.requestPath.pathComponents[1];
        [routesDictionary setObject:route forKey:key];
    }];
    routes = routesDictionary.copy;
}

@end

@implementation FCGIKitRoutingCenter

static FCGIKitRoutingCenter* sharedCenter;

+ (FCGIKitRoutingCenter *)sharedCenter
{
    if ( sharedCenter == nil ) {
        sharedCenter = [[FCGIKitRoutingCenter alloc] initWithRoutes:nil];
    }
    return sharedCenter;
}

- (id)initWithRoutes:(NSArray *)routesOrNil
{
    self = [self init];
    if (self != nil) {
        [self loadRoutes:routesOrNil];
    }
    return self;
}

- (FCGIKitRoute *)routeForRequestURI:(NSString *)requestURI
{
    NSString* key = requestURI.pathComponents[1];
    return routes[key];
}

- (NSDictionary *)allRoutes
{
    return routes.copy;
}


@end