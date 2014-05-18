//
//  FCGIKitViewController.h
//  FCGIKit
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCGIKitView, FCGIKitHTTPRequest, FCGIKitHTTPResponse;

@interface FCGIKitViewController : NSObject {
    FCGIKitView* _view;
    
    NSString* _nibName;
    NSBundle* _nibBundle;

    FCGIKitHTTPResponse* _response;
    FCGIKitHTTPRequest* _request;
    
    NSDictionary* _userInfo;
}

@property (nonatomic, retain) IBOutlet FCGIKitView* view;

@property (nonatomic, readonly) NSString* nibName;
@property (nonatomic, readonly) NSBundle* nibBundle;
@property (nonatomic, retain) FCGIKitHTTPRequest* request;
@property (nonatomic, retain) FCGIKitHTTPResponse* response;
@property (nonatomic, retain) NSDictionary* userInfo;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (void)loadView;

- (NSString*)postprocessView;
- (NSString*)presentViewController:(BOOL)writeData;

@end
