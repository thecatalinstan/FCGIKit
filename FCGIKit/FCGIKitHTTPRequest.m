//
//  FCGIKitHTTPRequest.m
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitHTTPRequest.h"
#import "FCGIRequest.h"
#import "NSString+FCGIKit.h"

//typedef struct FCGIKitKeyParseResultStruct {
//    Class objectClass;          // the class of the entry in the corresponding dictionary (NSObject, NSDictionary, NSArray)
//    const char* key;            // the key name
//    const char* dictionaryKey;  // set if the class is a Dictionary
//    const char* value;          // the string value;
//} FCGIKitKeyParseResult;

@interface FCGIKitKeyParseResult : NSObject {
}

@property (nonatomic, retain) Class objectClass;
@property (nonatomic, retain) NSString* key;
@property (nonatomic, retain) NSString* dictionaryKey;
@property (nonatomic, retain) NSString* value;

@end

@implementation FCGIKitKeyParseResult

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: objectClass=%@, key=%@, dictionaryKey=%@, value=%@>", self.className, self.objectClass, self.key, self.dictionaryKey, self.value ];
}

@end


@interface FCGIKitHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString;
- (FCGIKitKeyParseResult*)parseKey:(NSString *)key withValue:(NSString*)value;

@end

@implementation FCGIKitHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString
{
    NSArray* tokens = [queryString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    
    NSMutableArray* keyParsingResults = [NSMutableArray arrayWithCapacity:tokens.count];
    
    [tokens enumerateObjectsUsingBlock:^(id token, NSUInteger idx, BOOL *stop) {
        NSArray* pair = [token componentsSeparatedByString:@"="];
        NSString* key = [pair objectAtIndex:0];
        NSString* value = pair.count == 2 ? [pair objectAtIndex:1] : @"";
        FCGIKitKeyParseResult* result = [self parseKey:key withValue:value];
        [keyParsingResults setObject:result atIndexedSubscript:idx];
//        NSLog(@"%s: %@", __PRETTY_FUNCTION__, result);
    }];

    __block NSMutableArray* keys = [NSMutableArray array];
    __block NSMutableArray* objects = [NSMutableArray array];
    
    // Loop through the array and update types
    [keyParsingResults enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        FCGIKitKeyParseResult* keyInfo = obj;
        if ( ![keys containsObject:keyInfo.key] ) {
            [keys addObject:keyInfo.key];
        }
        NSUInteger currentKeyIdx = [keys indexOfObject:keyInfo.key];

        if ( keyInfo.objectClass == [NSString class] ) {
            [objects setObject:keyInfo.value atIndexedSubscript:currentKeyIdx];
        } else if ( keyInfo.objectClass == [NSArray class] ) {
            if ( objects.count - 1 < currentKeyIdx ) { // the item isn't there
                [objects setObject:[NSMutableArray array] atIndexedSubscript:currentKeyIdx];
            }
            NSMutableArray* valueArray;
            id existingValue = [objects objectAtIndex:currentKeyIdx];
            if ( [existingValue isKindOfClass:[NSString class]] ) {
                valueArray = [NSMutableArray array];
                [valueArray addObject:existingValue];
            } else if ([existingValue isKindOfClass:[NSDictionary class]]) {
                valueArray = existingValue;
                //TODO: asdf as
            } else {
                valueArray = existingValue;
            }
            [valueArray addObject:keyInfo.value];
            [objects setObject:valueArray atIndexedSubscript:currentKeyIdx];
        } else if ( keyInfo.objectClass == [NSDictionary class] ) {
            if ( objects.count - 1 < currentKeyIdx ) { // the item isn't there
                [objects setObject:[NSMutableDictionary dictionary] atIndexedSubscript:currentKeyIdx];
            }
            NSMutableDictionary* valueDictionary;
            id existingValue = [objects objectAtIndex:currentKeyIdx];
            if ( [existingValue isKindOfClass:[NSString class]] ) {
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
            [valueDictionary setObject:keyInfo.value forKey:keyInfo.dictionaryKey];
            [objects setObject:valueDictionary atIndexedSubscript:currentKeyIdx];
        }
    }];
    
    
    return [NSDictionary dictionaryWithObjects:objects forKeys:keys];
}

- (FCGIKitKeyParseResult*)parseKey:(NSString*)key withValue:(NSString*)value
{
    FCGIKitKeyParseResult* result = [[FCGIKitKeyParseResult alloc] init];

    result.value = value;

    // test if the string is an array
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(.+)\\[(.*)\\]" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray* matches = [regex matchesInString:key options:0 range:NSMakeRange(0, key.length)];
    if ( matches.count == 0 ) {
        result.objectClass = [NSString class];
        result.key = key;
        result.dictionaryKey = nil;
    } else {
        NSTextCheckingResult* match = [matches firstObject];
        result.objectClass = [NSArray class];
        result.key = [key substringWithRange:[match rangeAtIndex:1]];

        if ( match.numberOfRanges > 2 ) { // this should be a dictionary
            NSString* dictionaryKey = [key substringWithRange:[match rangeAtIndex:2]];
            if ( [dictionaryKey isEqualToString:@""] ) { // this is an array
                result.objectClass = [NSArray class];
                result.dictionaryKey = nil;
            } else { // this is a dictionary
                result.objectClass = [NSDictionary class];
                result.dictionaryKey = dictionaryKey;
            }
        } else { // this is an array
            result.objectClass = [NSArray class];
            result.dictionaryKey = nil;
        }
    }
    
//    NSLog(@"%s: %@", __PRETTY_FUNCTION__, result);
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
