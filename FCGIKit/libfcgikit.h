//
//  libfcgkit.h
//  libfcgkit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#ifdef DEBUG
#ifndef DLog
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif
#else
#ifndef DLog
#define DLog(...)
#endif
#endif

#import "FCGIKit.h"

#import "AsyncSocket.h"
#import "FCGIRequest.h"

#import "NSString+FCGIKit.h"
#import "NSHTTPCookie+FCGIKit.h"
#import "NSDate+RFC1123.h"

#import "FKApplicationDelegate.h"
#import "FKApplication.h"
#import "FCGIKitHTTPRequest.h"
#import "FCGIKitHTTPResponse.h"
#import "FCGIKitBackgroundThread.h"

#import "FCGIKitNib.h"
#import "FCGIKitView.h"
#import "FCGIKitViewController.h"
#import "FCGIKitRoute.h"
#import "FCGIKitRoutingCenter.h"