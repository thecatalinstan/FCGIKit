//
//  NSString+FCGIKit.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/12/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (FCGIKit)

- (NSString *)stringByDecodingURLEncodedString;
- (NSString *)URLEncodedString;

- (NSString*)uppercaseFirstLetterString;

@end
