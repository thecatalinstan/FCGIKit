//
//  FCGIKitView.h
//  FCGIKit
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCGIKitView : NSObject {
    NSString* _templateText;
}

@property (nonatomic, readonly, retain) NSString* templateText;

- (id)initWithTemplateText:(NSString *)templateText;
- render;

@end
