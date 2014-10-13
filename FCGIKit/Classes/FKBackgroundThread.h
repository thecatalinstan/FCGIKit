//
//  FCGIKitBackgroundThread.h
//  FCGIKit
//
//  Created by Cătălin Stan on 5/13/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FKApplication.h"

@class FKHTTPRequest, FKHTTPResponse;

@interface FKBackgroundThread : NSThread {
    FKHTTPRequest* _request;
    FKHTTPResponse* _response;
    NSDictionary* _userInfo;
}

@property (strong, nonatomic) FKHTTPRequest* request;
@property (strong, nonatomic) FKHTTPResponse* response;
@property (strong, nonatomic) NSDictionary* userInfo;

-(id)initWithUserInfo:(NSDictionary *)userInfo;
- (id)initWithTarget:(id)target selector:(SEL)aSelector userInfo:(NSDictionary*)userInfo didEndSelector:(SEL)didEndSelector;
- (id)initWithWorkerBlock:(FKAppBackgroundOperationBlock)block completion:(FKAppBackgroundOperationCompletionBlock)completion userInfo:(NSDictionary*)userInfo;

@end
