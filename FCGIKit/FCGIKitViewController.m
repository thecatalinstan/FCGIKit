//
//  FCGIKitViewController.m
//  FCGIKit
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FCGIKitViewController.h"
#import "FCGIKitView.h"
#import "FCGIKitNib.h"
#import "FCGIKitHTTPRequest.h"
#import "FCGIKitHTTPResponse.h"

@implementation FCGIKitViewController

@synthesize view = _view;
@synthesize nibBundle = _nibBundle;
@synthesize nibName = _nibName;
@synthesize response = _response;
@synthesize request = _request;
@synthesize userInfo = _userInfo;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil userInfo:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil userInfo:(NSDictionary *)userInfo
{
    self = [self init];
    if ( self != nil ) {
        variables = [NSMutableDictionary dictionary];

        _nibName = nibNameOrNil;
        _nibBundle = nibBundleOrNil;
        _userInfo = userInfo;

        [self loadView];
    }
    return self;
}

- (void)loadView
{
    // Load the NIB file
    FCGIKitNib* templateNib = [FCGIKitNib cachedNibForNibName:self.nibName];
    if ( templateNib == nil ) {
        templateNib = [[FCGIKitNib alloc] initWithNibNamed:self.nibName bundle:self.nibBundle];
        if ( templateNib != nil ) {
            [FCGIKitNib cacheNib:templateNib forNibName:self.nibName];
        }
    }
    
    NSString* templateText = templateNib != nil ? [templateNib stringUsingEncoding:NSUTF8StringEncoding] : @"";
 
    // Determine the view class to use
    Class viewClass = NSClassFromString([self.className stringByReplacingOccurrencesOfString:@"Controller" withString:@""]);
    if ( viewClass == nil ) {
        viewClass = [FCGIKitView class];
    }
    FCGIKitView* view = [[viewClass alloc] initWithTemplateText:templateText];
    [self setView:view];
    
    [self viewDidLoad];
}

- (void)viewDidLoad
{
}

- (void)didFinishLoading
{
}

- (NSString *)presentViewController:(BOOL)writeData
{
    NSString* output = [self.view render:self.allVariables];
    if ( writeData ) {
        [self.response writeString:output];
    }    
    return output;
}

- (NSDictionary *)allVariables
{
    return variables.copy;
}

- (void)addVariablesFromDictionary:(NSDictionary *)variablesDictionary
{
    [variables addEntriesFromDictionary:variablesDictionary];
}

- (void)removeAllVariables
{
    [variables removeAllObjects];
}

- (void)setObject:(id)object forVariableNamed:(NSString*)variableName
{
    [variables setObject:object forKey:variableName];
}

- (void)setObjects:(NSArray*)objects forVariablesNamed:(NSArray*)variableNames
{
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [variables setObject:obj forKey:variableNames[idx]];
    }];
}

- (void)removeVariableName:(NSString*)variableName
{
    [variables removeObjectForKey:variableName];
}

- (void)removeVariablesNamed:(NSArray *)variableNames
{
    [variables removeObjectsForKeys:variableNames];
}

@end
