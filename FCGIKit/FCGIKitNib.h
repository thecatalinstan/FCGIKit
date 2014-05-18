//
//  FCGIKitNib.h
//  FCGIKit
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCGIKitNib : NSObject {
    NSBundle* bundle;
    
    NSData* _data;
    NSString* _name;
}

@property (nonatomic, retain) NSData* data;
@property (nonatomic, retain) NSString* name;

- (id)initWithNibNamed:(NSString *)nibName bundle:(NSBundle *)bundle;
- (id)initWithNibData:(NSData *)nibData bundle:(NSBundle *)bundle;

- (NSString*)stringUsingEncoding:(NSStringEncoding)encoding;

@end
