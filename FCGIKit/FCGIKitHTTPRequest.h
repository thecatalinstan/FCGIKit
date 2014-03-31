//
//  FCGIKitHTTPRequest.h
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCGIRequest;

@interface FCGIKitHTTPRequest : NSObject {
    FCGIRequest* _FCGIRequest;
}

@property (nonatomic, retain) FCGIRequest* FCGIRequest;

- (id)initWithFCGIRequest:(FCGIRequest*)anFCGIRequest;
+ (id)requestWithFCGIRequest:(FCGIRequest*)anFCGIRequest;
    
@end
