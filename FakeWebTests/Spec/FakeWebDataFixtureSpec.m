

//#define KIWI_DISABLE_MACRO_API

#import "Kiwi.h"
#import "AsyncTestObject.h"

SPEC_BEGIN(FakeWebDataFixtureSpec)


describe(@"FakeWebDataFixture", ^{
    context(@"basic tests", ^{
        
        __block NSString* readFilePath;
        __block NSString* writeFilePath;
        __block NSData* textFileData;
        __block AsyncTestObject* tester;
        __block FakeWebDataFixture* fixture;
        
        beforeEach(^{
            readFilePath = [[NSBundle bundleWithIdentifier:@"net.dealforest.FakeWebTests"] pathForResource:@"FakeWebDataDocumentTest" ofType:@"txt"];
            textFileData = [NSData dataWithContentsOfFile:readFilePath];
            
            writeFilePath = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] path];
            
            tester = [[AsyncTestObject alloc] init];
            fixture = [[FakeWebDataFixture alloc] init];
        });
        
        afterEach(^{
            [tester release];
            tester = nil;
            [fixture release];
            fixture = nil;
        });
        
        it(@"did download data", ^{
            fixture.downloadDuration = 0.0;    // don't take anytime to transfer the data
            fixture.readFromDataPath = readFilePath;
            fixture.delegate = tester;
            
            [[[tester should] receive] dataTransferStarted:fixture];
            [[[tester should] receive] dataTransferDone:fixture];
            
            [fixture start];
            
            [[expectFutureValue( theValue(fixture.isProcessing) ) shouldEventuallyBeforeTimingOutAfter(2.0)] equal:theValue(NO)]; // Needs a bit more then a second.
            [[tester.progressData should] equal:textFileData];
        });
        
        it(@"cancel download", ^{   
            fixture.downloadDuration = 3.0;                     // take 3 seconds to transfer the data.
            fixture.processEveryMS = 250ull * NSEC_PER_MSEC;    // process data every 1/4 of a second
            fixture.readFromDataPath = readFilePath;
            fixture.delegate = tester;
            
            [[[tester should] receive] dataTransferDidCancel:fixture];
            
            [fixture start];
            
            [[expectFutureValue( theValue(tester.progress) ) shouldEventuallyBeforeTimingOutAfter(2.0)] beGreaterThan:theValue(0.50f)];
            
            [fixture stop];
            
            [[expectFutureValue( theValue(tester.didCancelProgressDownload) ) shouldEventually] equal:theValue(YES)];
            [[theValue(fixture.isProcessing) should] equal:theValue(NO)];
            [[tester.progressData shouldNot] beNil];
            [[tester.progressData shouldNot] equal:textFileData];
        });
        
        it(@"should handle progress downloading", ^{
            fixture.downloadDuration = 4.0;
            fixture.processEveryMS = 250ull * NSEC_PER_MSEC;   
            fixture.readFromDataPath = readFilePath;
            fixture.delegate = tester;
            
            [fixture start];
            
            [[expectFutureValue( theValue(tester.progress) ) shouldEventuallyBeforeTimingOutAfter(1.0)] beGreaterThanOrEqualTo:theValue(0.25f)];
            [[expectFutureValue( theValue(tester.progress) ) shouldEventuallyBeforeTimingOutAfter(2.0)] beGreaterThanOrEqualTo:theValue(0.50f)];
            [[expectFutureValue( theValue(tester.progress) ) shouldEventuallyBeforeTimingOutAfter(3.5)] beGreaterThanOrEqualTo:theValue(0.75f)];

            [[expectFutureValue( theValue(fixture.isProcessing) ) shouldEventuallyBeforeTimingOutAfter(2.0)] equal:theValue(NO)]; // Needs a bit more then a second.
        });
        
        it(@"write data to a file", ^{
            NSString* outputFile = [NSString stringWithFormat:@"%@out.strings", writeFilePath];
            
            fixture.downloadDuration = 2.0;
            fixture.processEveryMS = 100ull * NSEC_PER_MSEC;
            fixture.readFromDataPath = readFilePath;
            fixture.writeToDataPath = outputFile;
            fixture.delegate = tester;
            
            [fixture start];
            
            [[expectFutureValue( theValue(fixture.isProcessing) ) shouldEventuallyBeforeTimingOutAfter(3.0)] equal:theValue(NO)]; // Needs a bit more then a second.
            NSData* writtenData = [NSData dataWithContentsOfFile:outputFile];
            [[writtenData should] equal:textFileData];
            
            
            [[NSFileManager defaultManager] removeItemAtPath:outputFile error:nil];
        });
        
    });
});

SPEC_END