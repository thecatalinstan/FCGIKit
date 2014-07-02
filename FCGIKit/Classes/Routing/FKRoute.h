//
//  FCGIKitRoute.h
//  FCGIKit
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKViewController;

@interface FKRoute : NSObject {
    NSString* _requestPath;
    Class _controllerClass;
    NSString* _nibName;
    NSDictionary* _userInfo;
}

@property (nonatomic, retain) NSString* requestPath;
@property (atomic, assign) Class controllerClass;
@property (nonatomic, retain) NSString* nibName;
@property (nonatomic, retain) NSDictionary* userInfo;

- (id)initWithRequestPath:(NSString *)requestPath controllerClass:(Class)controllerClass nibName:(NSString*)nibName userInfo:(NSDictionary *)userInfo;
- (id)initWithInfoDictionary:(NSDictionary*)infoDictionary;

@end
