//
//  DWUUID.m
//
//  Copyright (c) 2012 Dan Wineman.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of 
//  this software and associated documentation files (the "Software"), to deal in 
//  the Software without restriction, including without limitation the rights to 
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
//  of the Software, and to permit persons to whom the Software is furnished to do 
//  so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all 
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
//  SOFTWARE.

#import "DWUUID.h"

@implementation DWUUID

- (id)init
{
	if ((self = [super init]))
		_CFUUID = CFUUIDCreate(NULL);
	return self;
}

+ (instancetype)UUID
{
    DWUUID* uuid = [[DWUUID alloc] init];
#if __has_feature(objc_arc)
    return uuid;
#else
    return [uuid autorelease];
#endif
    
}

- (id)initWithCoder:(NSCoder *)decoder
{
	return [self initWithString:[decoder decodeObjectForKey:@"UUID"]];
}

- (id)initWithString:(NSString *)stringRep
{
	if (stringRep && (self = [super init]))
	{
#if __has_feature(objc_arc)
		_CFUUID = CFUUIDCreateFromString(NULL, (__bridge CFStringRef)stringRep);
#else
		_CFUUID = CFUUIDCreateFromString(NULL, (CFStringRef)stringRep);
#endif
	}
	else
	{
#if !__has_feature(objc_arc)
		[self release];
#endif
		return nil;
	}
	return self;
}

- (void)dealloc
{
  if (_CFUUID)
		CFRelease(_CFUUID);
	
#if !__has_feature(objc_arc)
	[super dealloc];
#endif
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:[self stringValue] forKey:@"UUID"];
}

- (NSString *)stringValue
{
#if __has_feature(objc_arc)
	return (__bridge_transfer NSString *)CFUUIDCreateString(NULL, _CFUUID);
#else
	return [(NSString *)CFUUIDCreateString(NULL, _CFUUID) autorelease];
#endif
}

- (NSString *)UUIDString
{
    return self.stringValue;
}

- (CFUUIDBytes)bytes
{
	return CFUUIDGetUUIDBytes(_CFUUID);
}

- (BOOL)isEqual:(id)object
{
	if (object == self)
		return YES;
	
	if ([object isKindOfClass:[DWUUID class]])
	{
		CFUUIDBytes myBytes = [self bytes];
		CFUUIDBytes objectBytes = [(DWUUID *)object bytes];
		return (memcmp(&myBytes, &objectBytes, sizeof(CFUUIDBytes)) == 0);
	}
	
	return NO;
}

- (NSUInteger)hash
{
	return CFHash(_CFUUID);
}

- (id)copyWithZone:(NSZone *)zone
{
#if __has_feature(objc_arc)
	return self;
#else
	return [self retain];
#endif
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<UUID: %@>", [self stringValue]];
}

@end
