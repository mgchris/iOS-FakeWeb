

#import "Kiwi.h"
#import "AsyncTestObject.h"
#import "FakeWeb.h"
#import "NSURLConnection+FakeWeb_RestKit.h"
#import <RestKit/RestKit.h>
#import "AsyncTestObject+RestKit.h"

SPEC_BEGIN(FakeWebRestKitSpec)

describe(@"FakeWebRestKit", ^{
    
    __block NSString* loginURL;
    __block NSString* loginFixturePath;
    __block NSString* loginFixture;
    __block NSBundle* appBundle;
    
    beforeEach(^{
        appBundle = [NSBundle bundleWithIdentifier:@"net.dealforest.FakeWebTests"];
        loginURL = @"www.helloworld.com/REST/JSON/fakeUser/fakePassword";
        loginFixturePath = [appBundle pathForResource:@"LoginSucessfulFixture.json" ofType:nil];
        loginFixture = [NSString stringWithContentsOfFile:loginFixturePath encoding:NSUTF8StringEncoding error:nil];
        
    });
    
    context(@"Synchronous Calls", ^{
        it(@"simple Call", ^{
            [FakeWeb registerUri:loginURL method:@"GET" body:loginFixture status:200];
            
            NSURL* url = [NSURL URLWithString:loginURL];
            RKRequest* request = [RKRequest requestWithURL:url];
            RKResponse* response = [request sendSynchronously];
            
            [[response shouldNot] beNil];
            [[theValue( response.statusCode) should] equal:theValue(200)];
            [[[response bodyAsString] should] equal:loginFixture];
        });
    });
    
    context(@"Asynchronous Calls", ^{
       
        it(@"with response delay", ^{
            [FakeWeb registerUri:loginURL method:@"GET" body:loginFixture staus:200 statusMessage:nil withResponseDelay:1.0f];
            
            NSURL* url = [NSURL URLWithString:loginURL];
            RKRequest* request = [RKRequest requestWithURL:url];
            [request sendAsynchronously];
            
            [[expectFutureValue( [request response] ) shouldEventuallyBeforeTimingOutAfter( 1.25 )] beNonNil];
            
            [[[[request response] bodyAsString] should] equal:loginFixture];
            [[theValue([request response].statusCode) should] equal:theValue(200)];
        });
        
        it(@"with file path", ^{
            [FakeWeb registerUri:loginURL method:@"GET" staus:200 withResponseDelay:1.0f withFileDataPath:loginFixturePath];
            
            NSURL* url = [NSURL URLWithString:loginURL];
            RKRequest* request = [RKRequest requestWithURL:url];
            [request sendAsynchronously];
            
            [[expectFutureValue( [request response] ) shouldEventuallyBeforeTimingOutAfter( 1.25 )] beNonNil];
            
            [[[[request response] bodyAsString] should] equal:loginFixture];
        });
        
        it(@"with error", ^{
            NSError* error = [NSError errorWithDomain:@"UserErrorNotFound" code:500 userInfo:nil];
            [FakeWeb registerUri:loginURL method:@"GET" body:nil staus:500 statusMessage:nil withError:error withResponseDelay:1.0];
            
            AsyncTestObject* tester = [[[AsyncTestObject alloc] init] autorelease];
            
            NSURL* url = [NSURL URLWithString:loginURL];
            RKRequest* request = [RKRequest requestWithURL:url];
            request.delegate = tester;
            [request sendAsynchronously];
            
            [[expectFutureValue( tester.error ) shouldEventuallyBeforeTimingOutAfter( 1.25 )] beNonNil];
    
            [[tester.error should] equal:error];
        });
        
        it(@"with fixture", ^{
            [FakeWeb registerUri:loginURL
                          method:@"GET"
                           staus:200
                withFileDataPath:loginFixturePath
                  useDataFixture:YES
            withDownloadDuration:1.0];
            
            NSURL* url = [NSURL URLWithString:loginURL];
            RKRequest* request = [RKRequest requestWithURL:url];
            [request sendAsynchronously];
            
            [[expectFutureValue( [request response] ) shouldEventuallyBeforeTimingOutAfter( 1.25 )] beNonNil];
            
            [[[[request response] bodyAsString] should] equal:loginFixture];
        });
        
        it(@"cancel request", ^{
            [FakeWeb registerUri:loginURL
                          method:@"GET"
                           staus:200
                withFileDataPath:loginFixturePath
                  useDataFixture:YES
            withDownloadDuration:2.0];
            
            AsyncTestObject* tester = [[[AsyncTestObject alloc] init] autorelease];
            
            NSURL* url = [NSURL URLWithString:loginURL];
            RKRequest* request = [RKRequest requestWithURL:url];
            request.delegate = tester;
            [request sendAsynchronously];
            
            [tester waitFor];
            [request cancel];
            [tester waitFor]; // Got to wait a moment for the cancel request to get sent.
            
            [[theValue(tester.didCancelProgressDownload) should] beYes];
            [[tester.request should] equal:request];
        });
    });
    
    context(@"In Queue", ^{
        
        it(@"Async sucessful", ^{
            [FakeWeb registerUri:loginURL
                          method:@"GET"
                           staus:200
                withFileDataPath:loginFixturePath
                  useDataFixture:YES
            withDownloadDuration:0.5];
            
            RKRequestQueue* queue = [RKRequestQueue requestQueue];
            
            NSURL* url = [NSURL URLWithString:loginURL];
            RKRequest* request = [RKRequest requestWithURL:url];
            RKRequest* request1 = [RKRequest requestWithURL:url];
            RKRequest* request2 = [RKRequest requestWithURL:url];
            
            [queue addRequest:request];
            [queue addRequest:request1];
            [queue addRequest:request2];
            
            [queue start];
            
            [[expectFutureValue( [request2 response] ) shouldEventuallyBeforeTimingOutAfter( 1.25 )] beNonNil];
            
            [[[[request response] bodyAsString] should] equal:loginFixture];
            [[[[request1 response] bodyAsString] should] equal:loginFixture];
            [[[[request2 response] bodyAsString] should] equal:loginFixture];
        });
        
        it(@"Async cancel a reqest", ^{
            [FakeWeb registerUri:loginURL
                          method:@"GET"
                           staus:200
                withFileDataPath:loginFixturePath
                  useDataFixture:YES
            withDownloadDuration:1.0];
            
            RKRequestQueue* queue = [RKRequestQueue requestQueue];
            queue.concurrentRequestsLimit = 1;  // only have one items one at a time.
            
            NSURL* url = [NSURL URLWithString:loginURL];
            RKRequest* request = [RKRequest requestWithURL:url];
            RKRequest* request1 = [RKRequest requestWithURL:url];
            RKRequest* request2 = [RKRequest requestWithURL:url];
            
            [queue addRequest:request];
            [queue addRequest:request1];
            [queue addRequest:request2];
            
            [queue start];
            
            [[expectFutureValue( [request response] ) shouldEventuallyBeforeTimingOutAfter( 1.1 )] beNonNil];
            [queue cancelRequest:request1];
            [[expectFutureValue( [request2 response] ) shouldEventuallyBeforeTimingOutAfter( 1.5 )] beNonNil];
            
            [[[[request response] bodyAsString] should] equal:loginFixture];
            [[request1 response] shouldBeNil];
            [[[[request2 response] bodyAsString] should] equal:loginFixture];
        });
    });
});

SPEC_END