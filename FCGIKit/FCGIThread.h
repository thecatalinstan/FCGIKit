//
//  FCGIThread.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/27/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCGIKit.h"
#import "FCGIRecord.h"

@interface FCGIThread : NSThread {    
    BOOL _isCancelled;
    BOOL _isExecuting;
    BOOL _isFinished;
}


@end
