//
//  NSURLConnection+FakeWeb_RestKit.m
//  FakeWeb
//
//  Created by Chris Evans on 10/31/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import "NSURLConnection+FakeWeb_RestKit.h"
#import "NSURLConnection+FakeWeb.h"
#import "FakeWeb+Private.h"

@implementation NSURLConnection (FakeWeb_RestKit)

+ (void)load
{
    // If we try to use SwizzleClassMethod it fails to swizzle the methods, because it changes it to NSObject.
    Swizzle(self, @selector(initWithRequest:delegate:startImmediately:), @selector(override_initWithRequest:delegate:startImmediately:));
    Swizzle(self, @selector(start), @selector(override_start));
    Swizzle(self, @selector(cancel), @selector(override_cancel));
    Swizzle(self, @selector(dealloc), @selector(override_dealloc));
}

- (NSURLConnection*)override_initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
    // With this method we are just grabbing all of the callbacks needed and letting the class operate as expected.
    //  I wonder if I should send back a fake NSURLConnection, instead of a real object?
    
    FakeWebResponder *responder = [FakeWeb responderFor:[[request URL] absoluteString] method:[request HTTPMethod]];
    
    if( responder )
    {
        [FakeWeb setMatchingResponder:responder forRequest:self];
        
        FakeWebURLConnectionGlue* glue = [[FakeWebURLConnectionGlue alloc] init];
        glue.connectionRequest = request;
        glue.connectStartImmediately = startImmediately;
        glue.connectionDelegate = delegate;
        
        [FakeWebURLConnectionGlue storeGlue:glue forConnection:self];
        [glue release];
    }
    
    self = [self override_initWithRequest:request delegate:delegate startImmediately:startImmediately];
    
    return self;
}

-(void)override_start
{
    FakeWebURLConnectionGlue* glue = [FakeWebURLConnectionGlue glueForConnection:self];
    
    if( glue )
    {
        // We have glue code so we now run the show.
        
        FakeWebResponder *responder = [FakeWeb matchingResponderForRequest:self];
        if( responder )
        {
            if( responder.useDataFixture )
            {
                // Using fixture, let it handle it
                
                FakeWebDataFixture* fixture = [FakeWebResponder buildFixtureForResponder:responder];
                fixture.delegate = self;
                
                [FakeWebDataFixture storeFixture:fixture forRequest:self];
                
                [fixture start];
            }
            else
            {
                // Don't have a fixture, return data base on responder
                
                if( responder.error )
                {
                    // have error, do not send data.
                    
                    int64_t delayInSeconds = responder.delay;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self failRquestWithResponder:responder];
                    });
                }
                else
                {
                    NSData* data = nil;
                
                    if( [responder.dataPath length] > 0 )
                    {
                        data = [NSData dataWithContentsOfFile:responder.dataPath];
                    }
                    else
                    {
                        data = [responder.body dataUsingEncoding:NSUTF8StringEncoding];
                        
                    }
                    
                    int64_t delayInSeconds = responder.delay;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self dataTransfer:nil dataChunk:data];
                        [self dataTransferDone:nil];
                    });
                }
            }
        }
    }
    else
    {
        // Don't have glue code so just let it run normally.
        [self override_start];
    }
}

- (void)override_cancel
{
    FakeWebResponder *responder = [FakeWeb matchingResponderForRequest:self];
    if( responder )
    {
        FakeWebDataFixture* fixture = [FakeWebDataFixture fixtureForRequest:self];
        if(fixture)
        {
            // only if we have a fixture can we cancel a request
            [fixture stop];
        }
    }
    else
    {
        [self override_cancel];
    }
}

- (void)override_dealloc
{
    [FakeWeb removeMatchingResponderForRequest:self];
    [FakeWebDataFixture removeFixtureForRequest:self];
    [FakeWebURLConnectionGlue removeGlueFromStoreForConnection:self];
    [self override_dealloc];
}

#pragma mark -
- (void)failRquestWithResponder:(FakeWebResponder*)responder
{
    FakeWebURLConnectionGlue* glue = [FakeWebURLConnectionGlue glueForConnection:self];
    
    if( [glue.connectionDelegate respondsToSelector:@selector(connection:didFailWithError:)] )
    {
        [glue.connectionDelegate connection:self didFailWithError:[responder error]];
    }
}

#pragma mark - Fixture Delegates
- (void)dataTransfer:(FakeWebDataFixture*)transfer dataChunk:(NSData*)data
{
    FakeWebURLConnectionGlue* glue = [FakeWebURLConnectionGlue glueForConnection:self];
    
    if( [glue.connectionDelegate respondsToSelector:@selector(connection:didReceiveData:)] )
    {
        [glue.connectionDelegate connection:self didReceiveData:data];
    }
}

- (void)dataTransferDone:(FakeWebDataFixture *)transfer
{
    FakeWebURLConnectionGlue* glue = [FakeWebURLConnectionGlue glueForConnection:self];
    FakeWebResponder *responder = [FakeWeb matchingResponderForRequest:self];

    // First return the response
    NSHTTPURLResponse* response = [NSURLConnection createDummyResponse:glue.connectionRequest responder:responder];
    if( [glue.connectionDelegate respondsToSelector:@selector(connection:didReceiveResponse:)] )
    {
        [glue.connectionDelegate connection:self didReceiveResponse:response];
    }
    
    // The return the finished
    if( [glue.connectionDelegate respondsToSelector:@selector(connectionDidFinishLoading:)] )
    {
        [glue.connectionDelegate connectionDidFinishLoading:self];
    }
}

- (void)dataTransferDidCancel:(FakeWebDataFixture *)transfer
{
    // Does nothing for now...
}
@end

#pragma mark -
static NSMutableDictionary* glueConnectionDictionary = nil;

@implementation FakeWebURLConnectionGlue

+ (void)storeGlue:(FakeWebURLConnectionGlue*)glue forConnection:(NSURLConnection*)connection
{
    if( glueConnectionDictionary == nil ) {
        glueConnectionDictionary = [[NSMutableDictionary alloc] init];
    }
    
    if( glue && connection )
    {
        NSString* key = [NSString stringWithFormat:@"%p", connection];
        [glueConnectionDictionary setObject:glue forKey:key];
    }
}

+ (FakeWebURLConnectionGlue*)glueForConnection:(NSURLConnection*)connection
{
    FakeWebURLConnectionGlue* glue = nil;
    
    if( connection ) {
        NSString* key = [NSString stringWithFormat:@"%p", connection];
        glue = [glueConnectionDictionary objectForKey:key];
    }
    
    return glue;
}

+ (void)removeGlueFromStoreForConnection:(NSURLConnection*)connection
{
    if( connection ) {
        NSString* key = [NSString stringWithFormat:@"%p", connection];
        [glueConnectionDictionary removeObjectForKey:key];
    }
}

- (void)dealloc
{
    self.connectionDelegate = nil;
    self.connectionRequest = nil;
    [super dealloc];
}

@end