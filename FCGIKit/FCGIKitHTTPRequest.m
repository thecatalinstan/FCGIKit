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

@interface FCGIKitKeyParseResult : NSObject 

@property (nonatomic, assign) Class objectClass;
@property (nonatomic, assign) NSString* key;
@property (nonatomic, assign) NSString* dictionaryKey;
@property (nonatomic, assign) NSString* value;

@end

@implementation FCGIKitKeyParseResult

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
        FCGIKitKeyParseResult result = [self parseKey:key withValue:value];
        [keyParsingResults setObject:[NSValue valueWithBytes:&result objCType:@encode(FCGIKitKeyParseResult)] atIndexedSubscript:idx];
//        NSLog(@"class: %@, key: %s, dictionaryKey: %s, value: %s", result.objectClass, result.key, result.dictionaryKey, result.value);
    }];

    __block NSMutableArray* keys = [NSMutableArray array];
    __block NSMutableArray* objects = [NSMutableArray array];
    
    // Loop through the array and update types
    [keyParsingResults enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {


        FCGIKitKeyParseResult* keyInfo = malloc(sizeof(FCGIKitKeyParseResult));
        [obj getValue:keyInfo];
        
        NSString* keyString = [NSString stringWithCString:keyInfo->key encoding:NSUTF8StringEncoding];
//        keyString =  [NSString stringWithCString:[keyString cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
        if ( ![keys containsObject:keyString] ) {
            [keys addObject:keyString];
        }
        NSUInteger currentKeyIdx = [keys indexOfObject:keyString];

        NSString* valueString = [NSString stringWithCString:keyInfo->value encoding:NSUTF8StringEncoding];
        NSString* dictionaryKeyString = [NSString stringWithCString:keyInfo->dictionaryKey encoding:NSUTF8StringEncoding];
        
//        NSLog(@"Index: %lu { key: %@, dictionaryKey: %@, value: %@, class: %@ }", idx, keyString, dictionaryKeyString, valueString, NSStringFromClass(keyInfo->objectClass));
        
        if ( keyInfo->objectClass == [NSString class] ) {
            [objects setObject:valueString atIndexedSubscript:currentKeyIdx];
        } else if ( keyInfo->objectClass == [NSArray class] ) {
            if ( objects.count - 1 < currentKeyIdx ) { // the item isn't there
                [objects setObject:[NSMutableArray array] atIndexedSubscript:currentKeyIdx];
            }
            NSMutableArray* valueArray;
            id existingValue = [objects objectAtIndex:currentKeyIdx];
            if ( [existingValue isKindOfClass:[NSString class]] ) {
                valueArray = [NSMutableArray array];
                [valueArray addObject:existingValue];
            } else {
                valueArray = existingValue;
            }
            [valueArray addObject:valueString];
            [objects setObject:valueArray atIndexedSubscript:currentKeyIdx];
        } else if ( keyInfo->objectClass == [NSDictionary class] ) {
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
            [valueDictionary setObject:valueString forKey:dictionaryKeyString];
            [objects setObject:valueDictionary atIndexedSubscript:currentKeyIdx];
        }
    }];
    
    
    return [NSDictionary dictionaryWithObjects:objects forKeys:keys];
}

- (FCGIKitKeyParseResult*)parseKey:(NSString*)key withValue:(NSString*)value
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSError *error;
    
    Class objectClass;
    char* objectKey;
    char* objectDictionaryKey;

    char* objectValue = malloc(value.length + 1);
    [value getCString:objectValue maxLength:value.length + 1 encoding:NSUTF8StringEncoding];

    // test if the string is an array
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(.+)\\[(.*)\\]" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray* matches = [regex matchesInString:key options:0 range:NSMakeRange(0, key.length)];
    if ( matches.count == 0 ) {
        objectClass = [NSString class];
        objectKey = malloc(key.length + 1);
        [key getCString:objectKey maxLength:key.length + 1 encoding:NSUTF8StringEncoding];
        objectDictionaryKey = "";
    } else {
        NSTextCheckingResult* match = [matches firstObject];
        objectClass = [NSArray class];

        NSString* objectKeyString = [key substringWithRange:[match rangeAtIndex:1]];
        objectKey = malloc(objectKeyString.length + 1);
        [objectKeyString getCString:objectKey maxLength:objectKeyString.length + 1 encoding:NSUTF8StringEncoding];

        if ( match.numberOfRanges > 2 ) { // this should be a dictionary
            NSString* dictionaryKey = [key substringWithRange:[match rangeAtIndex:2]];
            if ( [dictionaryKey isEqualToString:@""] ) { // this is an array
                objectClass = [NSArray class];
                objectDictionaryKey = "";
            } else { // this is a dictionary
                objectClass = [NSDictionary class];
                objectDictionaryKey = malloc(dictionaryKey.length + 1);
                [dictionaryKey getCString:objectDictionaryKey maxLength:dictionaryKey.length + 1 encoding:NSUTF8StringEncoding];
            }
        } else { // this is an array
            objectClass = [NSArray class];
            objectDictionaryKey = "";
        }
    }

//    NSLog(@"class: %@, key: %s, dictionaryKey: %s, value: %s", objectClass, objectKey, objectDictionaryKey, objectValue);
    FCGIKitKeyParseResult result = { objectClass, objectKey, objectDictionaryKey, objectValue };
//    NSLog(@"class: %@, key: %s, dictionaryKey: %s, value: %s", result.objectClass, result.key, result.dictionaryKey, result.value);
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
