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
//@synthesize variables = _variables;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [self init];
    if ( self != nil ) {
        variables = [NSMutableDictionary dictionary];
        _nibName = nibNameOrNil;
        _nibBundle = nibBundleOrNil;
        [self loadView];
    }
    return self;
}

- (void)loadView
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    FCGIKitNib* templateNib = [[FCGIKitNib alloc] initWithNibNamed:self.nibName bundle:self.nibBundle];
    NSString* templateText = [templateNib stringUsingEncoding:NSUTF8StringEncoding];
    
//    NSLog(@" * TemplateNib: %@", templateNib);

    Class viewClass = NSClassFromString([self.className stringByReplacingOccurrencesOfString:@"Controller" withString:@""]);
//    NSLog(@" * Requested View Class: %@ - %@", [self.className stringByReplacingOccurrencesOfString:@"Controller" withString:@""], viewClass);
    if ( viewClass == nil ) {
        viewClass = [FCGIKitView class];
    }
//    NSLog(@" * View Class: %@", viewClass);
    
    FCGIKitView* view = [[viewClass alloc] initWithTemplateText:templateText];
    [self setView:view];
    
    [self viewDidLoad];
}

- (void)viewDidLoad
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)didFinishLoading
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (NSString *)presentViewController:(BOOL)writeData
{
    // NSLog(@"%s", __PRETTY_FUNCTION__);
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
