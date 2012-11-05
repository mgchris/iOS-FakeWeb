//
//  AsyncTestObject.h
//  FakeWeb
//
//  Copyright (c) 2012 Chris Evans (id:mgChris). All rights reserved.
//
//  Goal is to make writing test scripts a littl bit easier.

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "FakeWebDataFixture.h"

@interface AsyncTestObject : NSObject <FakeWebDataTransferDelegate>

@property (nonatomic, strong) ASIHTTPRequest* callbackRequest;


@property (nonatomic) BOOL didFinish;
@property (nonatomic) BOOL didFail;

@property (nonatomic) BOOL didFinishedProgressDownload;
@property (nonatomic) BOOL didCancelProgressDownload;
@property (nonatomic) CGFloat progress;
@property (nonatomic, strong) NSMutableData* progressData;

@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) id request;

+ (void)createAsyncTester:(AsyncTestObject**)tester createASIRequest:(ASIHTTPRequest**)request withURL:(NSURL*)url;

- (void)finishedWithASIHTTPRequest:(ASIHTTPRequest*)request;
- (void)failedWithASIHTTPRequest:(ASIHTTPRequest*)request;

- (void)callMeMaybe;

@end
