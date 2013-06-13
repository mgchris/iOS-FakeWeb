//
//  FakeWebAHIHTTPRequestTests.m
//  FakeWebTests
//
//  Created by Toshirhio Morimoto on 5/15/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#define KIWI_DISABLE_MACRO_API

#import "Kiwi.h"
#import "FakeWeb.h"
#import "ASIHTTPRequest+FakeWeb.h"
#import "ASIFormDataRequest.h"

#import "AsyncTestObject.h"

SPEC_BEGIN(FakeWebAHIHTTPRequestSpec)

describe(@"ASIHTTPRequest+FakeWeb", ^{
    NSURL __block *url;
    
    beforeEach(^{
        url = [NSURL URLWithString:@"http://exsample.com"];
        [FakeWeb cleanRegistry];
        [FakeWeb setAllowNetConnet:YES];
    });
    
    context(@"when empty registered uri", ^{
        context(@"registerUri", ^{
            it(@"normal process", ^{
                [FakeWeb registerUri:@"http://exsample.com" method:@"GET" body:@"hoge" status:200];
                
                ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
                [request startSynchronous];
                [[theValue([request responseStatusCode]) should] equal:theValue(200)];
                [[[request responseString] should] equal:@"hoge"];
            });
        });
    });
    
    context(@"when don't allowd net conncect", ^{
        context(@"setAllowNetConnet", ^{
            afterEach(^{
                [FakeWeb setAllowNetConnet:YES]; 
            });
            
            it(@"process is allowed net connect", ^{
                [FakeWeb setAllowNetConnet:YES];
                
                [FakeWeb registerUri:@"http://exsample.com" method:@"GET" body:@"hoge" status:200];
                
                ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
                [request startSynchronous];
                [[theValue([request responseStatusCode]) should] equal:theValue(200)];
                [[[request responseString] should] equal:@"hoge"];
            });

            it(@"process is not allowed net connect on non-regsiter", ^{
                [FakeWeb setAllowNetConnet:NO];
                
                [[theBlock(^{ 
                    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
                    [request startSynchronous];
                }) should] raiseWithName:@"FakeWebNotAllowedNetConnetException"];
            });
            
            it(@"process is not allowed net connect already regsiter", ^{
                [FakeWeb setAllowNetConnet:NO];
                [FakeWeb registerUri:@"http://exsample.com" method:@"GET" body:@"hoge" status:200];
                
                [[theBlock(^{ 
                    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
                    [request startSynchronous];
                }) should] raiseWithName:@"FakeWebNotAllowedNetConnetException"];
            });
        });
    });
    
    context(@"when adding a custom status to the response", ^{
        context(@"registerUri", ^{
            it(@"regsitetr 404 response", ^{
                [FakeWeb registerUri:[url absoluteString] method:@"GET" body:@"Nothing to be found 'round here" status:404 statusMessage:@"Not Found"];
                
                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                [request startSynchronous];
                [[theValue([request responseStatusCode]) should] equal:theValue(404)];
                [[[request responseString] should] equal:@"Nothing to be found 'round here"];
            });
        });
    });
    
    context(@"when responding to any HTTP method", ^{
        context(@"registerUri", ^{
            it(@"request method is GET and POST", ^{
                [FakeWeb registerUri:[url absoluteString] method:@"ANY" body:@"Nothing to be found 'round here" status:404 statusMessage:@"Not Found"];
                
                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                [request startSynchronous];
                [[theValue([request responseStatusCode]) should] equal:theValue(404)];
                [[[request responseString] should] equal:@"Nothing to be found 'round here"];
                
                ASIFormDataRequest *formRequest;
                formRequest = [ASIFormDataRequest requestWithURL:url];
                [formRequest setRequestMethod:@"POST"];
                [formRequest startSynchronous];
                [[theValue([request responseStatusCode]) should] equal:theValue(404)];
                [[[request responseString] should] equal:@"Nothing to be found 'round here"];
            });
        });
    });
    
    context(@"when rotating responses", ^{
        context(@"registerUri", ^{
            it(@"regsitetr 2 response", ^{
                NSArray *responses = [NSArray arrayWithObjects:
                                      [NSDictionary dictionaryWithObjectsAndKeys:@"hoge", @"body", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:@"fuga", @"body", @"404", @"status", @"Not Found", @"statusMessage", nil],
                                      nil];
                [FakeWeb registerUri:[url absoluteString] method:@"GET" rotatingResponse:responses];

                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                [request startSynchronous];
                [[[request responseString] should] equal:@"hoge"];
                [[theValue([request responseStatusCode]) should] equal:theValue(200)];
                [[[request responseStatusMessage] should] equal:@"OK"];
                
                [request startSynchronous];
                [[[request responseString] should] equal:@"fuga"];
                [[theValue([request responseStatusCode]) should] equal:theValue(404)];
                [[[request responseStatusMessage] should] equal:@"Not Found"];
                
                [request startSynchronous];
                [[[request responseString] should] equal:@"hoge"];
                [[theValue([request responseStatusCode]) should] equal:theValue(200)];
                [[[request responseStatusMessage] should] equal:@"OK"];
            });
        });
    });
    
    context(@"when need authorization request", ^{
        context(@"registerUri", ^{
            it(@"input valid parameter", ^{
                [FakeWeb registerUri:[url absoluteString] method:@"GET" body:@"Unauthorized" status:401 statusMessage:@"Unauthorized"];
                
                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                [request startSynchronous];
                [[[request responseString] should] equal:@"Unauthorized"];
                
                [FakeWeb registerUri:[url absoluteString] method:@"GET" body:@"Authorized"];

                [request setUsername:@"user"];
                [request setPassword:@"pass"];
                [request startSynchronous];
                [[[request responseString] should] equal:@"Authorized"];
            });
        });
    });
    
    context(@"when async request with ASI", ^{
        context(@"registerUri", ^{
            __block NSString* filePath;
            __block NSData* textFileData;
            
            beforeEach(^{
                filePath = [[NSBundle bundleWithIdentifier:@"net.dealforest.FakeWebTests"] pathForResource:@"FakeWebDataDocumentTest" ofType:@"txt"];
                textFileData = [NSData dataWithContentsOfFile:filePath];
            });
            
            it(@"normal process", ^{
                [FakeWeb registerUri:[url absoluteString] method:@"GET" body:@"hoge"];
                
                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                [request startAsynchronous];
                [[expectFutureValue([request responseString]) shouldEventually] equal:@"hoge"];
            });
            
            it(@"error when Synchronous", ^{
                NSError* error = [NSError errorWithDomain:@"This error is part of the test" code:500 userInfo:nil];
                [FakeWeb registerUri:[url absoluteString] method:@"GET" body:@"Error Test" status:500 statusMessage:nil withError:error withResponseDelay:0.3];
                
                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                [request startSynchronous];
                
                NSError* requestError = [request error];
                [request shouldNotBeNil];
                [[requestError shouldEventually] equal:error];
                [[theValue([requestError code]) should] equal:theValue(500)];
                [[[requestError domain] should] equal:@"This error is part of the test"];
            });
            
            it(@"return data", ^{
                [FakeWeb registerUri:[url absoluteString] method:@"GET" status:200 withResponseDelay:0.3 withFileDataPath:filePath];
                
                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                [request startAsynchronous];
                [[expectFutureValue([request responseData]) shouldEventually] beNonNil];
                [[[request responseData] should] equal:textFileData];
            });
            
            it(@"return data", ^{
                [FakeWeb registerUri:[url absoluteString] method:@"GET" status:200 withResponseDelay:0.3 withFileDataPath:filePath];
                
                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                [request startAsynchronous];
                [[expectFutureValue([request responseData]) shouldEventually] beNonNil];
                [[[request responseData] should] equal:textFileData];
            });
            
            it(@"finish callback", ^{
                
                [FakeWeb registerUri:[url absoluteString] method:@"GET" status:200 withResponseDelay:0.3 withFileDataPath:filePath];
                
                AsyncTestObject* handler = [[[AsyncTestObject alloc] init] autorelease];
                
                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                
                [request setDelegate:handler];
                [request setDidFinishSelector:@selector(finishedWithASIHTTPRequest:)];
                
                [request startAsynchronous];
                
                [[expectFutureValue( theValue(handler.didFinish) ) shouldEventually] beTrue];
                [[handler.callbackRequest shouldNot] beNil];
                [[handler.callbackRequest should] equal:request];
            });
            
            it(@"fail callback", ^{
                NSError* error = [NSError errorWithDomain:@"Error when testing callback" code:500 userInfo:nil];
                [FakeWeb registerUri:[url absoluteString] method:@"GET" body:nil status:404 statusMessage:nil withError:error withResponseDelay:0.3];
                
                AsyncTestObject* handler = [[[AsyncTestObject alloc] init] autorelease];
                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                [request setDelegate:handler];
                [request setDidFailSelector:@selector(failedWithASIHTTPRequest:)];
                [request startAsynchronous];
                
                [[expectFutureValue( theValue(handler.didFail) ) shouldEventually] beTrue];
                [[handler.callbackRequest shouldNot] beNil];
                
                [[[handler.callbackRequest error] should] equal:error];
                [[theValue([[handler.callbackRequest error] code]) should] equal:theValue(500)];
                [[[[handler.callbackRequest error] domain] should] equal:@"Error when testing callback"];
            });
            
            it(@"completion block", ^{
                
                [FakeWeb registerUri:[url absoluteString] method:@"GET" status:200 withResponseDelay:0.3 withFileDataPath:filePath];
                
                AsyncTestObject* tester = [AsyncTestObject mock];
                
                ASIHTTPRequest *request;
                request = [ASIHTTPRequest requestWithURL:url];
                [request setCompletionBlock:^{
                    [tester description];
                }];
                
                [request startAsynchronous];
                
                [[[tester shouldEventually] receive] description];
            });
            
            it(@"change registerURI after setting it", ^{
                
                [FakeWeb registerUri:[url absoluteString] method:@"GET" status:200 withResponseDelay:0.3 withFileDataPath:filePath];
                AsyncTestObject* sucessfulHandler = [[[AsyncTestObject alloc] init] autorelease];
                
                ASIHTTPRequest *sucessfulRequest;
                sucessfulRequest = [ASIHTTPRequest requestWithURL:url];
                
                [sucessfulRequest setDelegate:sucessfulHandler];
                [sucessfulRequest setDidFinishSelector:@selector(finishedWithASIHTTPRequest:)];
                
                [sucessfulRequest startAsynchronous];
                
                [[expectFutureValue( theValue(sucessfulHandler.didFinish) ) shouldEventually] beTrue];
                [[sucessfulHandler.callbackRequest shouldNot] beNil];
                [[sucessfulHandler.callbackRequest should] equal:sucessfulRequest];
                [[theValue( sucessfulHandler.callbackRequest.responseStatusCode ) should] equal:theValue(200)];
                
                [FakeWeb registerUri:[url absoluteString] method:@"GET" status:500 withResponseDelay:0.3 withFileDataPath:filePath];
                AsyncTestObject* failedHandler = [[[AsyncTestObject alloc] init] autorelease];
                
                ASIHTTPRequest *failedRequest;
                failedRequest = [ASIHTTPRequest requestWithURL:url];
                
                [failedRequest setDelegate:failedHandler];
                [failedRequest setDidFinishSelector:@selector(finishedWithASIHTTPRequest:)];
                
                [failedRequest startAsynchronous];
                
                [[expectFutureValue( theValue(failedHandler.didFinish) ) shouldEventually] beTrue];
                [[failedHandler.callbackRequest shouldNot] beNil];
                [[failedHandler.callbackRequest should] equal:failedRequest];
                [[theValue( failedHandler.callbackRequest.responseStatusCode ) should] equal:theValue(500)];
                
            });
            
            context(@" Using data fixture",^{
                __block AsyncTestObject* tester = nil;
                __block ASIHTTPRequest* request = nil;
                __block NSString* downloadPath = nil;
                
                beforeEach(^{
                    tester = [[[AsyncTestObject alloc] init] autorelease];
                    request = [ASIHTTPRequest requestWithURL:url];
                    downloadPath = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] path];
                });
                
                it(@"Progressive download", ^{
                    [FakeWeb registerUri:[url absoluteString] method:@"GET" status:200 withFileDataPath:filePath useDataFixture:YES withDownloadDuration:3.0];
                    
                    [request setDownloadProgressDelegate:tester];
                    
                    [request startAsynchronous];
                    
                    [[expectFutureValue( theValue(tester.progress) ) shouldEventuallyBeforeTimingOutAfter(1.5)] beGreaterThanOrEqualTo:theValue(0.25f)];
                    [[expectFutureValue( theValue(tester.progress) ) shouldEventuallyBeforeTimingOutAfter(2.0)] beGreaterThanOrEqualTo:theValue(0.50f)];
                    [[expectFutureValue( theValue(tester.progress) ) shouldEventuallyBeforeTimingOutAfter(3.5)] beGreaterThanOrEqualTo:theValue(1.0f)];
                    [[[request responseData] should] equal:textFileData];
                });
                
                it(@"write to path", ^{
                    [FakeWeb registerUri:[url absoluteString] method:@"GET" status:200 withFileDataPath:filePath useDataFixture:YES withDownloadDuration:1.0];
                    
                    NSString* outFile = [NSString stringWithFormat:@"%@outFile.txt", downloadPath];

                    [request setDownloadDestinationPath:outFile];   
                    [request setDownloadProgressDelegate:tester];
                    
                    [request startAsynchronous];
                    
                    [[expectFutureValue( theValue(tester.progress) ) shouldEventuallyBeforeTimingOutAfter(1.5)] beGreaterThanOrEqualTo:theValue(1.0f)]; // wait until done.
                    
                    NSData* writtenData = [NSData dataWithContentsOfFile:outFile];
                    [[writtenData should] equal:textFileData];
                    
                    [[NSFileManager defaultManager] removeItemAtPath:outFile error:nil];
                });
            });
        });
    });
});

SPEC_END
