//
//  FCGIKitHTTPRequest.m
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKit.h"
#import "FCGIKitHTTPRequest.h"
#import "FCGIRequest.h"
#import "NSString+FCGIKit.h"

@interface FCGIKitKeyParseResult : NSObject {
    Class _objectClass;
    NSString* _key;
    NSString* _dictionaryKey;
    NSString* _value;
}

@property (atomic, assign) Class objectClass;
@property (nonatomic, retain) NSString* key;
@property (nonatomic, retain) NSString* dictionaryKey;
@property (nonatomic, retain) NSString* value;

@end

@implementation FCGIKitKeyParseResult

@synthesize objectClass = _objectClass;
@synthesize key = _key;
@synthesize dictionaryKey = _dictionaryKey;
@synthesize value = _value;

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: objectClass=%@, key=%@, dictionaryKey=%@, value=%@>", self.className, self.objectClass, self.key, self.dictionaryKey, self.value ];
}

@end


@interface FCGIKitHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString;
- (FCGIKitKeyParseResult*)parseKey:(NSString *)key withValue:(NSString*)value;

- (NSArray*)parseMultipartFormData:(NSData*)data boundary:(NSString*)boundary;
- (NSDictionary*)parseMultipartFormDataPart:(NSData*)data;
- (NSDictionary*)parseHeaderValue:(NSString*)value;

@end

@implementation FCGIKitHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString
{
    NSArray* tokens = [queryString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    
    NSMutableDictionary* result = [NSMutableDictionary dictionaryWithCapacity:tokens.count];
    [tokens enumerateObjectsUsingBlock:^(id token, NSUInteger idx, BOOL *stop) {
        NSArray* pair = [token componentsSeparatedByString:@"="];
        NSString* key = [pair objectAtIndex:0];
        NSString* value = pair.count == 2 ? [pair objectAtIndex:1] : @"";
        [result setObject:value.stringByDecodingURLEncodedString forKey:key.stringByDecodingURLEncodedString];
    }];
    
    return result.copy;

    NSMutableArray* keyParsingResults = [NSMutableArray arrayWithCapacity:tokens.count];
    [tokens enumerateObjectsUsingBlock:^(id token, NSUInteger idx, BOOL *stop) {
        NSArray* pair = [token componentsSeparatedByString:@"="];
        NSString* key = [pair objectAtIndex:0];
        NSString* value = pair.count == 2 ? [pair objectAtIndex:1] : @"";
        FCGIKitKeyParseResult* result = [self parseKey:key withValue:value];
        [keyParsingResults setObject:result atIndexedSubscript:idx];
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
            
            if ( [[NSNumber numberWithLong:( objects.count - 1 )] compare:[NSNumber numberWithUnsignedLong:currentKeyIdx]] == NSOrderedAscending ) {
                [objects setObject:[NSString string] atIndexedSubscript:currentKeyIdx];
            }
            id existingValue = [objects objectAtIndex:currentKeyIdx];
            
            if ( [existingValue isKindOfClass:[NSArray class]] ) {
                [existingValue addObject:keyInfo.value];
            } else if ( [existingValue isKindOfClass:[NSDictionary class]] ) {
                [existingValue setObject:keyInfo.value forKey:[NSUUID UUID]];
            } else {
                [objects setObject:keyInfo.value atIndexedSubscript:currentKeyIdx];
            }
            
        } else if ( keyInfo.objectClass == [NSArray class] ) {
            
            if ( [[NSNumber numberWithLong:( objects.count - 1 )] compare:[NSNumber numberWithUnsignedLong:currentKeyIdx]] == NSOrderedAscending ) {
                [objects setObject:[NSMutableArray array] atIndexedSubscript:currentKeyIdx];
            }
            id existingValue = [objects objectAtIndex:currentKeyIdx];

            if ( [existingValue isKindOfClass:[NSString class]] ) {
                NSMutableArray* valueArray = [NSMutableArray arrayWithObjects:existingValue, keyInfo.value, nil];
                [objects setObject:valueArray atIndexedSubscript:currentKeyIdx];
            } else if ([existingValue isKindOfClass:[NSDictionary class]]) {
                [existingValue setObject:keyInfo.value forKey:[NSUUID UUID]];
            } else {
                [existingValue addObject:keyInfo.value];
            }
            
        } else if ( keyInfo.objectClass == [NSDictionary class] ) {
            
            if ( [[NSNumber numberWithLong:( objects.count - 1 )] compare:[NSNumber numberWithUnsignedLong:currentKeyIdx]] == NSOrderedAscending ) {
                [objects setObject:[NSMutableDictionary dictionary] atIndexedSubscript:currentKeyIdx];
            }
            id existingValue = [objects objectAtIndex:currentKeyIdx];
            
            if ( [existingValue isKindOfClass:[NSString class]] ) {
                NSMutableDictionary* valueDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:existingValue, [NSUUID UUID], keyInfo.value, keyInfo.dictionaryKey, nil];
                [objects setObject:valueDictionary atIndexedSubscript:currentKeyIdx];
            } else if ( [existingValue isKindOfClass:[NSArray class]] ) {
                NSMutableDictionary* valueDictionary = [NSMutableDictionary dictionary];
                [existingValue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [valueDictionary setObject:obj forKey:[NSUUID UUID]];
                }];
                [valueDictionary setObject:keyInfo.value forKey:keyInfo.dictionaryKey];
                [objects setObject:valueDictionary atIndexedSubscript:currentKeyIdx];
            } else {
                [existingValue setObject:keyInfo.value forKey:keyInfo.dictionaryKey];
            }

        }
    }];
    
    return [NSDictionary dictionaryWithObjects:objects forKeys:keys];
}

- (FCGIKitKeyParseResult*)parseKey:(NSString*)key withValue:(NSString*)value
{
    FCGIKitKeyParseResult* result = [[FCGIKitKeyParseResult alloc] init];

    key = [key stringByDecodingURLEncodedString];
    result.value = [value stringByDecodingURLEncodedString];

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


- (NSArray*)parseMultipartFormData:(NSData*)data boundary:(NSString*)boundary
{
    if ( boundary == nil ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Boundary cannot be nil." userInfo:nil];
        return nil;
    }

    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* files = [[NSMutableDictionary alloc] init];
    
    boundary = [NSString stringWithFormat:@"--%@", boundary];
    NSData* boundaryData = [boundary dataUsingEncoding:NSASCIIStringEncoding];
    
    NSRange partRange = NSMakeRange(boundaryData.length + 2, 0);
    NSRange searchRange = NSMakeRange(boundaryData.length, data.length - boundaryData.length);
    NSRange resultRange;
    
    do {
        resultRange = [data rangeOfData:boundaryData options:0 range:searchRange];
        if ( resultRange.location != NSNotFound ) {
            partRange.length = resultRange.location - partRange.location - 2;
            
            NSDictionary* part = [self parseMultipartFormDataPart:[data subdataWithRange:partRange]];
            if ( part != nil ) {
                NSString* key = part.allKeys[0];
                id value = part[key];
                if ( [value isKindOfClass:[NSString class]] ) {
                    [post setObject:value forKey:key];
                } else {
                    [files setObject:value forKey:key];
                }
            }
            partRange.location = resultRange.location + resultRange.length + 2;
        }
        
        searchRange.location = resultRange.location + resultRange.length;
        searchRange.length = data.length - resultRange.location - resultRange.length;
        
    } while (resultRange.location != NSNotFound);
    
    
    return @[post.copy, files.copy];
}

- (NSDictionary*)parseMultipartFormDataPart:(NSData*)data
{
    NSData* headersSeparator = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    
    NSRange separatorRange = [data rangeOfData:headersSeparator options:0 range:NSMakeRange(0, data.length)];
    if ( separatorRange.location == NSNotFound ) {
        return nil;
    }
    
    __block NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    NSArray* headerLines = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, separatorRange.location)] encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\r\n"];
    [headerLines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray* parts = [obj componentsSeparatedByString:@": "];
        [headers setObject:[self parseHeaderValue:parts[1]] forKey:parts[0]];
    }];
    
    NSData* bodyData = [data subdataWithRange:NSMakeRange(separatorRange.location + separatorRange.length, data.length - separatorRange.location - separatorRange.length)];
    NSString* key = headers[@"Content-Disposition"][@"name"];
    if ( headers[@"Content-Disposition"][@"filename"] == nil || [headers[@"Content-Disposition"][@"filename"] isEqualToString:@""] ) {
        NSString* value = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        return @{ key: value};
    } else {
        NSString* tmpFilename = [FCGIApp.temporaryDirectoryLocation stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
        [bodyData writeToFile:tmpFilename atomically:NO];
        NSDictionary* value = @{ FCGIKitFileNameKey: headers[@"Content-Disposition"][@"filename"],
                                 FCGIKitFileTmpNameKey: tmpFilename,
                                 FCGIKitFileContentTypeKey: headers[@"Content-Type"][@"_"],
                                 FCGIKitFileSizeKey: [NSNumber numberWithLong:bodyData.length]};
        return @{ key: value };
    }
}


- (NSDictionary*)parseHeaderValue:(NSString*)value
{
    __block NSMutableDictionary* paramsDictionary = [NSMutableDictionary dictionary];
    NSArray* parts = [value componentsSeparatedByString:@";"];
    [parts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray* partKV = [obj componentsSeparatedByString:@"="];
        if ( partKV.count == 1 ) {
            [paramsDictionary setObject:partKV[0] forKey:@"_"];
        } else {
            [paramsDictionary setObject:[partKV[1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \""]] forKey:[partKV[0] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]]];
        }
    }];
    return [paramsDictionary copy];
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
        
        // Server
        _server = [NSDictionary dictionaryWithDictionary:_FCGIRequest.parameters];
        
        // GET
        if ( [_server.allKeys containsObject:@"QUERY_STRING"] ) {
            _get = [self parseQueryString:_server[@"QUERY_STRING"]];
        } else {
            _get = [NSDictionary dictionary];
        }
        
        // POST
        NSDictionary* contentType = [self parseHeaderValue:_server[@"CONTENT_TYPE"]];
        if ( [_server[@"REQUEST_METHOD"] isEqualToString:@"POST"] && [contentType[@"_"] isEqualToString:@"application/x-www-form-urlencoded"] ) {
            _post = [self parseQueryString:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]];
            _files = [NSDictionary dictionary];
        } else if([_server[@"REQUEST_METHOD"] isEqualToString:@"POST"] && [contentType[@"_"] isEqualToString:@"multipart/form-data"]) {
            if ( body.length == 0 || contentType[@"boundary"] == nil ) {
                _post = [NSDictionary dictionary];
                _files = [NSDictionary dictionary];
            } else {
                NSArray* postInfo = [self parseMultipartFormData:body boundary:contentType[@"boundary"]];
                _post = postInfo[0];
                _files = postInfo[1];
            }
        } else {
            _post = [NSDictionary dictionary];
            _files = [NSDictionary dictionary];
        }
        
        
    }
    return self;
}

+ (id)requestWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
    return [[FCGIKitHTTPRequest alloc] initWithFCGIRequest:anFCGIRequest];
}

- (NSDictionary *)serverVars
{
    return _server;
}

- (NSDictionary *)getVars
{
    return _get;
}

- (NSDictionary *)cookieVars
{
    return _cookie;
}

- (NSDictionary *)postVars
{
    return _post;
}

- (NSDictionary *)files
{
    return _files;
}


@end
