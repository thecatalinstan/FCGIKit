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
    CFStringRef returnCFString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, encodedCFString, (CFStringRef)@"!*'();:&=$,/?%#[]", kCFStringEncodingUTF8);
    NSString* returnString = (__bridge_transfer NSString*)returnCFString;
    returnString = [returnString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return returnString;
}

- (NSString *)URLEncodedString
{
    CFStringRef encodedCFString = (__bridge CFStringRef)self;
    CFStringRef returnCFString = CFURLCreateStringByAddingPercentEscapes(NULL, encodedCFString, NULL, (CFStringRef)@"!*'();:&=$,/?%#[]", kCFStringEncodingUTF8 );
    NSString *returnString = (__bridge_transfer NSString *)returnCFString;
    returnString = [returnString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    return returnString;
}

- (NSString *)uppercaseFirstLetterString
{
    return [[self substringToIndex:1].uppercaseString stringByAppendingString:[self substringFromIndex:1].lowercaseString];
}

- (NSString *)stringbyFormattingHTTPHeader
{
    NSMutableArray* words = [[self componentsSeparatedByString:@"-"] mutableCopy];
    [words enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [words setObject:[obj uppercaseFirstLetterString] atIndexedSubscript:idx];
    }];
    return [words componentsJoinedByString:@"-"];
}

@end
