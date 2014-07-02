//
//  NSObject+subscripts.h
//  SnappyApp
//
//  Created by Cătălin Stan on 6/28/14.
//
//

#import <Foundation/Foundation.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1080

@interface NSDictionary(subscripts)
- (id)objectForKeyedSubscript:(id)key;
@end

@interface NSMutableDictionary(subscripts)
- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;
@end

@interface NSArray(subscripts)
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
@end

@interface NSMutableArray(subscripts)
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;
@end

#endif
