//
//  FCGIKitRoutingCenter.h
//  FCGIKit
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCGIKitRoute;

@interface FCGIKitRoutingCenter : NSObject {
    NSDictionary* routes;
}

+ (FCGIKitRoutingCenter*)sharedCenter;

- (id)initWithRoutes:(NSArray*)routesOrNil;

- (FCGIKitRoute *)routeForRequestURI:(NSString*)requestURI;
- (NSDictionary *)allRoutes;

@end
