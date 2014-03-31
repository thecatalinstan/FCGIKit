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

#import "AsyncSocket.h"
#import "FCGIApplicationDelegate.h"
#import "FCGIApplication.h"
#import "FCGIRecord.h"
#import "FCGIBeginRequestRecord.h"
#import "FCGIParamsRecord.h"
#import "FCGIByteStreamRecord.h"
#import "FCGIRequest.h"
#import "FCGIKitHTTPRequest.h"
#import "FCGIKitHTTPResponse.h"