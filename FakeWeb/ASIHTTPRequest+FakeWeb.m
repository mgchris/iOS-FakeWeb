//
//  ASIHTTPRequest+FakeWeb.m
//  FakeWeb
//
//  Created by Toshirhio Morimoto on 5/15/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import "ASIHTTPRequest+FakeWeb.h"
#import "FakeWeb+Private.h"

@implementation ASIHTTPRequest (FakeWeb)

+ (void)load
{
    Class c = [ASIHTTPRequest class];
    Swizzle(c, @selector(startSynchronous), @selector(override_startSynchronous));
    Swizzle(c, @selector(startAsynchronous), @selector(override_startAsynchronous));
    Swizzle(c, @selector(responseStatusCode), @selector(override_responseStatusCode));
    Swizzle(c, @selector(responseStatusMessage), @selector(override_responseStatusMessage));
    Swizzle(c, @selector(responseString), @selector(override_responseString));
    Swizzle(c, @selector(responseData), @selector(override_responseData));
    Swizzle(c, @selector(error), @selector(override_error));
    Swizzle(c, @selector(dealloc), @selector(override_dealloc));    // Need to remove request from
}

#pragma mark -
-(void) override_startSynchronous
{
    FakeWebResponder *responder = [FakeWeb responderFor:[self.url absoluteString] method:self.requestMethod];
    
    if (responder) {
        [FakeWeb setMatchingResponder:responder forRequest:self];
        return;
    }
    
    [self override_startSynchronous];
}

-(void) override_startAsynchronous
{
    FakeWebResponder *responder = [FakeWeb responderFor:[self.url absoluteString] method:self.requestMethod];
    
    if (responder)
    {
        [FakeWeb setMatchingResponder:responder forRequest:self];
        
        if( responder.useDataFixture ) {
            FakeWebDataFixture* fixture = [FakeWebResponder buildFixtureForResponder:responder];
            fixture.delegate = self;

            if( [[self downloadDestinationPath] length] > 0 )
            {
                fixture.writeToDataPath = [self downloadDestinationPath];
            }
            
            [FakeWebDataFixture storeFixture:fixture forRequest:self];
            
            [fixture start];
            
        } else {
            [self finishedWithAsyncWithResponder:responder];
        }
    }
    else
    {
        [self override_startAsynchronous];
    }
}

- (NSInteger)override_responseStatusCode
{
    FakeWebResponder *responder = [FakeWeb matchingResponderForRequest:self];
    return responder
    ? [responder status]
    : [self override_responseStatusCode];
}

- (NSString *)override_responseStatusMessage
{
    FakeWebResponder *responder = [FakeWeb matchingResponderForRequest:self];
    return responder
    ? [responder statusMessage]
    : [self override_responseStatusMessage];
}

- (NSString *)override_responseString
{
    FakeWebResponder *responder = [FakeWeb matchingResponderForRequest:self];
    return responder
    ? [responder body]
    : [self override_responseString];
}

- (NSData *)override_responseData
{
    FakeWebResponder *responder = [FakeWeb matchingResponderForRequest:self];
    
    // If you call response data you are expecting data back.
    if( responder && [responder.dataPath length] > 0 ) {
        return [NSData dataWithContentsOfFile:responder.dataPath];
    }
    return [self override_responseData];
}

- (NSError*)override_error
{
    FakeWebResponder *responder = [FakeWeb matchingResponderForRequest:self];
    return responder
    ? responder.error
    : [self override_error];
}

- (void)override_dealloc
{
    [FakeWeb cleanUpForRequest:self];
    [FakeWebDataFixture removeFixtureForRequest:self];
    [self override_dealloc];
}

#pragma mark -
- (void)finishedWithAsyncWithResponder:(FakeWebResponder*)responder
{
    if (responder)
    {
        double delayInSeconds = responder.delay;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            if( responder.error ) {
                if (delegate && [delegate respondsToSelector:didFailSelector]) {
                    [delegate performSelector:didFailSelector withObject:self];
                }
                
                if(failureBlock){
                    failureBlock();
                }
                
            } else {
                if (delegate && [delegate respondsToSelector:didFinishSelector]) {
                    [delegate performSelector:didFinishSelector withObject:self];
                }
                
                if( completionBlock ) {
                    completionBlock();
                }
            }
        });
    }
}

#pragma mark - Fixture Delegates
- (void)dataTransfer:(FakeWebDataFixture*)transfer dataChunk:(NSData*)data
{
    unsigned long long bytesReadSoFar = transfer.bytesRead;
	unsigned long long value = [data length];
	
    [ASIHTTPRequest performSelector:@selector(request:didReceiveBytes:) onTarget:&queue withObject:self amount:&value callerToRetain:self];
	[ASIHTTPRequest performSelector:@selector(request:didReceiveBytes:) onTarget:&downloadProgressDelegate withObject:self amount:&value callerToRetain:self];
    
	[ASIHTTPRequest updateProgressIndicator:&downloadProgressDelegate withProgress:bytesReadSoFar ofTotal:transfer.sizeOfFile];
}

- (void)dataTransferDone:(FakeWebDataFixture *)transfer
{
    FakeWebResponder *responder = [FakeWeb matchingResponderForRequest:self];
    [self finishedWithAsyncWithResponder:responder];
}

- (void)dataTransferDidCancel:(FakeWebDataFixture *)transfer
{
    FakeWebResponder *responder = [FakeWeb matchingResponderForRequest:self];
    [self finishedWithAsyncWithResponder:responder];
}

@end
