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

@interface FKBackgroundThread () {
	SEL _selector;
	SEL _didEndSelector;
	id _target;
	
	FKAppBackgroundOperationBlock _workerBlock;
	FKAppBackgroundOperationCompletionBlock _completionBlock;
}

@property (assign, nonatomic) SEL selector;
@property (assign, nonatomic) SEL didEndSelector;
@property (strong, nonatomic) id target;

@property (copy, atomic) FKAppBackgroundOperationBlock workerBlock;
@property (copy, atomic) FKAppBackgroundOperationCompletionBlock completionBlock;

@end

@implementation FKBackgroundThread

@synthesize request = _request;
@synthesize response = _response;
@synthesize userInfo = _userInfo;
@synthesize selector = _selector;
@synthesize didEndSelector = _didEndSelector;
@synthesize target = _target;

-(id)initWithUserInfo:(NSDictionary *)userInfo
{
	self = [super init];
	if ( self != nil ) {
		_request = userInfo[FKRequestKey];
		_response = userInfo[FKResponseKey];
		_userInfo = userInfo;
		
		self.name = [NSString stringWithFormat:@"%@", [self className]];
		self.threadPriority = 0.1;
	}
	return self;
}

-(id)initWithTarget:(id)target selector:(SEL)aSelector userInfo:(NSDictionary *)userInfo didEndSelector:(SEL)didEndSelector
{
    self = [self initWithUserInfo:userInfo];
    if ( self != nil ) {
        _selector = aSelector;
        _didEndSelector = didEndSelector;
        _target = target;
		
		self.name = [NSString stringWithFormat:@"%@ [%@ %@]", [self className], [self.target className], NSStringFromSelector(self.selector)];
    }
    return self;
}

- (id)initWithWorkerBlock:(FKAppBackgroundOperationBlock)workerBlock completion:(FKAppBackgroundOperationCompletionBlock)completionBlock userInfo:(NSDictionary *)userInfo
{
	self = [self initWithUserInfo:userInfo];
	if ( self != nil ) {
		_workerBlock = workerBlock;
		_completionBlock = completionBlock;
	}
	return self;
}


- (void)main
{
	id result;
	if ( self.target != nil ) {
//		result = objc_msgSend(self.target, self.selector, self.request, self.userInfo);
	} else {
		result = self.workerBlock(self.userInfo);
	}
	
    NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
    if ( result != nil ) {
        [newUserInfo setObject:result forKey:FKResultKey];
    }
	
	if ( self.target != nil ){
		[FKApp performBackgroundDidEndSelector:self.didEndSelector onTarget:self.target userInfo:newUserInfo.
		 copy];
	} else {
		[FKApp performBackgroundDidEndSelector:@selector(completionBlockDidEndSelectorUserInfo:) onTarget:self userInfo:newUserInfo.copy];
	}
}

- (void)completionBlockDidEndSelectorUserInfo:(NSDictionary*)userInfo
{
	self.completionBlock(userInfo);
}

@end;
