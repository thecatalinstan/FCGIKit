//
//  FCGIKitHTTPRequest.m
//  FCGIKit
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FKHTTPRequest.h"
#import "FCGIRequest.h"
#import "NSString+FCGIKit.h"
#import "DWUUID.h"

@interface FKHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString;

- (NSArray*)parseMultipartFormData:(NSData*)data boundary:(NSString*)boundary;
- (NSDictionary*)parseMultipartFormDataPart:(NSData*)data;
- (NSDictionary*)parseHeaderValue:(NSString*)value;

@end

@implementation FKHTTPRequest (Private)

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
        NSString* tmpFilename = [[FKApp temporaryDirectoryLocation] stringByAppendingPathComponent:[[DWUUID UUID] UUIDString]];
        [bodyData writeToFile:tmpFilename atomically:NO];
        NSDictionary* value = @{ FKFileNameKey: headers[@"Content-Disposition"][@"filename"],
                                 FKFileTmpNameKey: tmpFilename,
                                 FKFileContentTypeKey: headers[@"Content-Type"][@"_"],
                                 FKFileSizeKey: [NSNumber numberWithLong:bodyData.length]};
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

@implementation FKHTTPRequest

@synthesize FCGIRequest = _FCGIRequest;

- (id)initWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    
    self = [self init];
    if ( self != nil ) {

        _FCGIRequest = anFCGIRequest;
        
        body = _FCGIRequest.stdinData;
        
        _url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", @"http", _FCGIRequest.parameters[@"HTTP_HOST"], _FCGIRequest.parameters[@"REQUEST_URI"]]];
                
        // SERVER
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
        
        // COOKIE
        _cookie = [self parseHeaderValue:_server[@"HTTP_COOKIE"]];
    }
    return self;
}

+ (id)requestWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
    return [[FKHTTPRequest alloc] initWithFCGIRequest:anFCGIRequest];
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
