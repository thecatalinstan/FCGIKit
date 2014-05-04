//
//  NSString+FCGIKit.m
//  FCGIKit
//
//  Created by Cătălin Stan on 4/12/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "NSString+FCGIKit.h"

@implementation NSString (FCGIKit)

- (NSString *)stringByDecodingURLEncodedString
{
    CFStringRef encodedCFString = (__bridge CFStringRef)self;
    CFStringRef returnCFString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, encodedCFString, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUnicode);
    NSString* returnString = (__bridge_transfer NSString*)returnCFString;
    return returnString;
}

- (NSString *)URLEncodedString
{
    CFStringRef encodedCFString = (__bridge CFStringRef)self;
    CFStringRef returnCFString = CFURLCreateStringByAddingPercentEscapes(NULL, encodedCFString, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUnicode );
    NSString *returnString = (__bridge_transfer NSString *)returnCFString;
    return returnString;
}

@end
