//
//  FCGIKitContactView.m
//  Test-FCGIKit
//
//  Created by Cătălin Stan on 5/20/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitContactView.h"
#import <libfcgikit.h>

@implementation FCGIKitContactView

- (id)render:(NSDictionary *)variables
{
    __block NSString* parsedText = self.templateText;
    [variables enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        parsedText = [parsedText stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"[%@]", key] withString:obj];
    }];
    return parsedText;
}

@end
