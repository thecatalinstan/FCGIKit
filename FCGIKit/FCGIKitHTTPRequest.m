//
//  FCGIKitHTTPRequest.m
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitHTTPRequest.h"
#import "FCGIRequest.h"

typedef struct FCGIKitKeyParseResultStruct {
    Class objectClass;      // the class of the entry in the corresponding dictionary (NSObject, NSDictionary, NSArray)
    const char* baseName;
    const char* key;        // set if the class is a Dictionary
    const char* value;      // the string value;
} FCGIKitKeyParseResult;

@interface FCGIKitHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString;
- (FCGIKitKeyParseResult)parseKey:(NSString *)key withValue:(NSString*)value;

@end

@implementation FCGIKitHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString
{
    NSArray* tokens = [queryString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    
    FCGIKitKeyParseResult keyParsingResults[tokens.count];
    FCGIKitKeyParseResult *keyInfoResults = keyParsingResults;
    
    [tokens enumerateObjectsUsingBlock:^(id token, NSUInteger idx, BOOL *stop) {
        NSArray* pair = [token componentsSeparatedByString:@"="];
        NSString* key = [pair objectAtIndex:0];
        NSString* value = pair.count == 2 ? [pair objectAtIndex:1] : @"";
        keyInfoResults[idx] = [self parseKey:key withValue:value];
    }];

    NSMutableArray* keys = [NSMutableArray array];
    NSMutableArray* objects = [NSMutableArray array];
    
    // Loop through the array and update types
    for (NSUInteger idx = 0; idx < tokens.count; idx++, keyInfoResults++ ) {
        NSString* baseNameString = [NSString stringWithCString:keyInfoResults->baseName encoding:NSUTF8StringEncoding];
        if ( ![keys containsObject:baseNameString] ) {
            [keys addObject:baseNameString];
        }
        NSUInteger currentKeyIdx = [keys indexOfObject:baseNameString];

        NSString* valueString = [NSString stringWithCString:keyInfoResults->value encoding:NSUTF8StringEncoding];
        NSString* keyString = [NSString stringWithCString:keyInfoResults->key encoding:NSUTF8StringEncoding];
        
        if ( keyInfoResults->objectClass == [NSObject class] ) {
            [objects setObject:valueString atIndexedSubscript:currentKeyIdx];
        } else if ( keyInfoResults->objectClass == [NSArray class] ) {
            if ( objects.count - 1 < currentKeyIdx ) { // the item isn't there
                [objects setObject:[NSMutableArray array] atIndexedSubscript:currentKeyIdx];
            }
            NSMutableArray* valueArray;
            id existingValue = [objects objectAtIndex:currentKeyIdx];
            if ( [existingValue isKindOfClass:[NSObject class]] ) {
                valueArray = [NSMutableArray array];
                [valueArray addObject:existingValue];
            } else {
                valueArray = existingValue;
            }
            [valueArray addObject:valueString];
        } else if ( keyInfoResults->objectClass == [NSDictionary class] ) {
            if ( objects.count - 1 < currentKeyIdx ) { // the item isn't there
                [objects setObject:[NSMutableDictionary dictionary] atIndexedSubscript:currentKeyIdx];
            }
            NSMutableDictionary* valueDictionary;
            id existingValue = [objects objectAtIndex:currentKeyIdx];
            if ( [existingValue isKindOfClass:[NSObject class]] ) {
                valueDictionary = [NSMutableDictionary dictionary];
                [valueDictionary setObject:existingValue forKey:@"0"];
            } else if ( [existingValue isKindOfClass:[NSArray class]] ) {
                valueDictionary = [NSMutableDictionary dictionary];
                for (NSUInteger i = 0; i < [existingValue count]; i++) {
                    [valueDictionary setObject:[existingValue objectAtIndex:i] forKey:[NSString stringWithFormat:@"%lu", i]];
                }
            } else {
                valueDictionary = existingValue;
            }
            [valueDictionary setObject:valueString forKey:keyString];
        }
        
        
        
    }
    
    
    return [NSDictionary dictionaryWithObjects:objects forKeys:keys];
}

- (FCGIKitKeyParseResult)parseKey:(NSString *)key withValue:(NSString*)value
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    FCGIKitKeyParseResult result = { [NSObject class], "", "", [value cStringUsingEncoding:NSUTF8StringEncoding] } ;
    NSError *error;
    // test if the string is an array
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(.+)\\[(.*)\\]" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray* matches = [regex matchesInString:key options:0 range:NSMakeRange(0, key.length)];
    if ( matches.count == 0 ) {
        result.objectClass = [NSObject class];
        result.baseName = [key cStringUsingEncoding:NSUTF8StringEncoding];
    } else {
        NSTextCheckingResult* match = [matches firstObject];
        result.objectClass = [NSArray class];
        result.baseName = [[key substringWithRange:[match rangeAtIndex:1]] cStringUsingEncoding:NSUTF8StringEncoding];

//        for (NSUInteger i = 0; i < match.numberOfRanges; i++) {
//            NSLog(@" * %@", [key substringWithRange: [match rangeAtIndex:i]]);
//        }

        if ( match.numberOfRanges > 2 ) { // this should be a dictionary
            NSString* dictionaryKey = [key substringWithRange:[match rangeAtIndex:2]];
            if ( [dictionaryKey isEqualToString:@""] ) { // this is an array
                result.objectClass = [NSArray class];
            } else { // this is a dictionary
                result.objectClass = [NSDictionary class];
                result.key = [dictionaryKey cStringUsingEncoding:NSUTF8StringEncoding];
            }
        } else { // this is an array
            result.objectClass = [NSArray class];
        }
    }
    
    NSLog(@"{class: %@, baseName: %s, key: %s, value: %s }", result.objectClass, result.baseName, result.key, result.value );
    
    return result;
}

@end

@implementation FCGIKitHTTPRequest

@synthesize FCGIRequest = _FCGIRequest;

- (id)initWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    self = [self init];
    if ( self != nil ) {

        _FCGIRequest = anFCGIRequest;
        
        body = _FCGIRequest.stdinData;
        
        _server = [NSDictionary dictionaryWithDictionary:_FCGIRequest.parameters];
        
        if ( [_server.allKeys containsObject:@"QUERY_STRING"] ) {
            _get = [self parseQueryString:[_server objectForKey:@"QUERY_STRING"]];
        } else {
            _get = [NSDictionary dictionary];
        }
        
        if ( [[_server objectForKey:@"REQUEST_METHOD"] isEqualToString:@"POST"] && [[_server objectForKey:@"CONTENT_TYPE"] isEqualToString:@"application/x-www-form-urlencoded"] ) {
            _post = [self parseQueryString:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]];
        } else if([[_server objectForKey:@"REQUEST_METHOD"] isEqualToString:@"POST"] && [[_server objectForKey:@"CONTENT_TYPE"] isEqualToString:@"multipart/form-data"]) {
            _post = [NSDictionary dictionary];
        } else {
            _post = [NSDictionary dictionary];
        }
        
        
    }
    return self;
}

+ (id)requestWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
    return [[FCGIKitHTTPRequest alloc] initWithFCGIRequest:anFCGIRequest];
}

- (NSDictionary *)serverFields
{
    return _server;
}

- (NSDictionary *)getFields
{
    return _get;
}

- (NSDictionary *)cookieFields
{
    return _cookie;
}

- (NSDictionary *)postFields
{
    return _post;
}

@end
