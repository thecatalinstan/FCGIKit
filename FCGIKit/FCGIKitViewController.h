//
//  FCGIKitViewController.h
//  FCGIKit
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCGIKitView, FKHTTPRequest, FKHTTPResponse;

@interface FCGIKitViewController : NSObject {
    FCGIKitView* _view;
    
    NSString* _nibName;
    NSBundle* _nibBundle;

    FKHTTPResponse* _response;
    FKHTTPRequest* _request;
    
    NSDictionary* _userInfo;
    
    NSMutableDictionary* variables;
}

@property (nonatomic, retain) IBOutlet FCGIKitView* view;

@property (nonatomic, readonly) NSString* nibName;
@property (nonatomic, readonly) NSBundle* nibBundle;
@property (nonatomic, retain) FKHTTPRequest* request;
@property (nonatomic, retain) FKHTTPResponse* response;
@property (nonatomic, retain) NSDictionary* userInfo;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil userInfo:(NSDictionary*)userInfo;

- (void)loadView;
- (void)viewDidLoad;
- (void)didFinishLoading;
- (NSString*)presentViewController:(BOOL)writeData;

- (NSDictionary*)allVariables;
- (void)addVariablesFromDictionary:(NSDictionary*)variablesDictionary;
- (void)removeAllVariables;
- (void)setObject:(id)object forVariableNamed:(NSString*)variableName;
- (void)setObjects:(NSArray*)objects forVariablesNamed:(NSArray*)variableNames;
- (void)removeVariableName:(NSString*)variableName;
- (void)removeVariablesNamed:(NSArray *)variableNames;


@end
