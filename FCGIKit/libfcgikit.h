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

#import "FCGIApplicationDelegate.h"
#import "FCGIApplication.h"
#import "FCGITypes.h"
