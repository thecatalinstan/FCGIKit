//
//  FCGIKitBackgroundThread.h
//  FCGIKit
//
//  Created by Cătălin Stan on 5/13/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FKHTTPRequest, FKHTTPResponse;

@interface FKBackgroundThread : NSThread {
    FKHTTPRequest* _request;
    FKHTTPResponse* _response;
    NSDictionary* _userInfo;
    SEL _selector;
    SEL _didEndSelector;
    id _target;
}

@property (strong, nonatomic) FKHTTPRequest* request;
@property (strong, nonatomic) FKHTTPResponse* response;
@property (strong, nonatomic) NSDictionary* userInfo;
@property (assign, nonatomic) SEL selector;
@property (assign, nonatomic) SEL didEndSelector;
@property (strong, nonatomic) id target;

- (id)initWithTarget:(id)target selector:(SEL)aSelector userInfo:(NSDictionary*)userInfo didEndSelector:(SEL)didEndSelector;

@end
