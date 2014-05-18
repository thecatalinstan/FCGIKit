//
//  FCGIKitNib.m
//  FCGIKit
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitNib.h"

@interface FCGIKitNib (Private)

- (void)loadData:(NSData *)data error:(NSError *__autoreleasing *)error;

@end

@implementation FCGIKitNib (Private)

- (void)loadData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if ( data != nil ) {
        [self setData:data];
        return;
    }
    NSString* path = [bundle pathForResource:self.name ofType:@"html"];
    NSLog(@" * Name: %@", self.name);
    NSLog(@" * Path: %@", path);
    data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:error];
    [self setData:data];
}

@end

@implementation FCGIKitNib

@synthesize data = _data;
@synthesize name = _name;

- (id)initWithNibNamed:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [self init];
    if ( self != nil ) {
        bundle = nibBundle == nil ? [NSBundle mainBundle] : nibBundle;
        _name = nibName;
        NSError* error;
        [self loadData:nil error:&error];
        if ( error ) {
            @throw [[NSException alloc] initWithName:NSInvalidArgumentException reason:error.localizedDescription userInfo:nil];
        }
    }
    return self;
}

- (id)initWithNibData:(NSData *)nibData bundle:(NSBundle *)nibBundle
{
    self = [self init];
    if ( self != nil ) {
        bundle = nibBundle == nil ? [NSBundle mainBundle] : nibBundle;
        _name = nil;
        NSError *error;
        [self loadData:nil error:&error];
        if ( error ) {
            @throw [[NSException alloc] initWithName:NSInvalidArgumentException reason:error.localizedDescription userInfo:nil];
        }
    }
    return self;
}

- (NSString *)stringUsingEncoding:(NSStringEncoding)encoding
{
    return [[NSString alloc] initWithData:self.data encoding:encoding];
}

@end
