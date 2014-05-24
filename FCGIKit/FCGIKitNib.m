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
    if ( data != nil ) {
        [self setData:data];
        return;
    }
    
    NSString* path = [bundle pathForResource:self.name ofType:@"html"];
    if ( path != nil ) {
        data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:error];
        [self setData:data];
    }
}

@end

@implementation FCGIKitNib

@synthesize data = _data;
@synthesize name = _name;

static NSMutableDictionary* nibCache;

- (id)initWithNibNamed:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [self init];
    if ( self != nil ) {
        bundle = nibBundle == nil ? [NSBundle mainBundle] : nibBundle;
        _name = nibName;
        [self loadData:nil error:nil];
    }
    return self;
}

- (NSString *)stringUsingEncoding:(NSStringEncoding)encoding
{
    return [[NSString alloc] initWithData:self.data encoding:encoding];
}

+ (void)cacheNibNames:(NSArray*)nibNames bundle:(NSBundle*)nibBundle
{
    [nibNames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        FCGIKitNib* nib = [[FCGIKitNib alloc] initWithNibNamed:obj bundle:nibBundle];
        if ( nib != nil ) {
            [FCGIKitNib cacheNib:nib forNibName:obj];
        }
    }];    
}

+ (FCGIKitNib *)cachedNibForNibName:(NSString*)nibName
{
    return nibCache[nibName];
}

+ (void)cacheNib:(FCGIKitNib *)nib forNibName:(NSString*)nibName
{
    if ( nibCache == nil ) {
        nibCache = [NSMutableDictionary dictionary];
    }
    [nibCache setObject:nib forKey:nibName];
}

@end
