//
//  AsyncTestObject.m
//  FakeWeb
//
//  Created by Chris Evans on 10/24/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import "AsyncTestObject.h"

@implementation AsyncTestObject

+ (void)createAsyncTester:(AsyncTestObject**)tester createASIRequest:(ASIHTTPRequest**)request withURL:(NSURL*)url {
    
    if( tester && request )
    {
        *tester = [[[AsyncTestObject alloc] init] autorelease];
        *request = [ASIHTTPRequest requestWithURL:url];
        [*request setDelegate:*tester];
        [*request setDidFailSelector:@selector(failedWithASIHTTPRequest:)];
        [*request setDidFinishSelector:@selector(finishedWithASIHTTPRequest:)];
    }
}

#pragma mark -
- (void)finishedWithASIHTTPRequest:(ASIHTTPRequest*)request
{
    self.callbackRequest = request;
    self.didFinish = YES;
}

- (void)failedWithASIHTTPRequest:(ASIHTTPRequest*)request
{
    self.callbackRequest = request;
    self.didFail = YES;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"<%p> Request: <%p> DidFail: %@  DidFinish: %@", self, self.callbackRequest,
            (self.didFail ? @"YES" : @"NO"), (self.didFinish ? @"YES" : @"NO")];
}

- (void)callMeMaybe
{
    NSLog(@"Cookie!");
}

#pragma mark -
- (void)dataTransferStarted:(FakeWebDataFixture *)transfer
{
    self.progressData = [NSMutableData data];
}

- (void)dataTransfer:(FakeWebDataFixture*)transfer dataChunk:(NSData*)data
{
    [self.progressData appendBytes:[data bytes] length:[data length]];
    self.progress = transfer.downloadPercentage;
}

- (void)dataTransferDone:(FakeWebDataFixture *)transfer
{
    self.didFinishedProgressDownload = YES;
}

- (void)dataTransferDidCancel:(FakeWebDataFixture *)transfer
{
    self.didCancelProgressDownload = YES;
}

@end
