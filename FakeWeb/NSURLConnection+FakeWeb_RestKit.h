//
//  NSURLConnection+FakeWeb_RestKit.h
//  FakeWeb
//
//  Created by Chris Evans on 10/31/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FakeWebDataFixture.h"

@interface NSURLConnection (FakeWeb_RestKit) <FakeWebDataTransferDelegate>

- (NSURLConnection*)override_initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately;
- (void)override_start;

@end



@interface FakeWebURLConnectionGlue : NSObject

@property (nonatomic, assign) id <NSURLConnectionDelegate, NSURLConnectionDataDelegate> connectionDelegate;
@property (nonatomic, retain) NSURLRequest* connectionRequest;
@property (nonatomic, assign) BOOL connectStartImmediately;

+ (void)storeGlue:(FakeWebURLConnectionGlue*)glue forConnection:(NSURLConnection*)connection;
+ (FakeWebURLConnectionGlue*)glueForConnection:(NSURLConnection*)connection;
+ (void)removeGlueFromStoreForConnection:(NSURLConnection*)connection;

@end