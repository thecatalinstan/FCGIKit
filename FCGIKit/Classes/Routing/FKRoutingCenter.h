//
//  FCGIKitRoutingCenter.h
//  FCGIKit
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKRoute;

@interface FKRoutingCenter : NSObject {
    NSDictionary* routes;
}

+ (FKRoutingCenter*)sharedCenter;

- (id)initWithRoutes:(NSArray*)routesOrNil;

- (FKRoute *)routeForRequestURI:(NSString*)requestURI;
- (NSDictionary *)allRoutes;

@end
