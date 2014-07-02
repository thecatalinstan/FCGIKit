//
//  FCGIKitBackgroundThread.m
//  FCGIKit
//
//  Created by Cătălin Stan on 5/13/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <objc/message.h>

#import "FKBackgroundThread.h"
#import "FCGIKit.h"
#import "FKApplication.h"
#import "FKHTTPRequest.h"
#import "FKHTTPResponse.h"

@implementation FKBackgroundThread

@synthesize request = _request;
@synthesize response = _response;
@synthesize userInfo = _userInfo;
@synthesize selector = _selector;
@synthesize didEndSelector = _didEndSelector;
@synthesize target = _target;

-(id)initWithTarget:(id)target selector:(SEL)aSelector userInfo:(NSDictionary *)userInfo didEndSelector:(SEL)didEndSelector
{
    self = [super init];
    if ( self != nil ) {
        _request = userInfo[FCGIKitRequestKey];
        _response = userInfo[FCGIKitResponseKey];
        _selector = aSelector;
        _didEndSelector = didEndSelector;
        _userInfo = userInfo;
        _target = target;
        
        self.name = [NSString stringWithFormat:@"%@ [%@ %@]", [self className], [self.target className], NSStringFromSelector(self.selector)];
    }
    return self;
}


- (void)main
{
    id result = objc_msgSend(self.target, self.selector, self.request, self.userInfo);
    NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
    if ( result != nil ) {
        [newUserInfo setObject:result forKey:FCGIKitResultKey];
    }
    [FCGIApp performBackgroundDidEndSelector:self.didEndSelector onTarget:self.target userInfo:newUserInfo.copy];
}

@end;
