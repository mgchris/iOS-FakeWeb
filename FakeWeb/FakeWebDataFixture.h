//
//  FakeWebDataTransfer.h
//  FakeWeb
//
//  Copyright (c) 2012 Chris Evans (id:mgChris). All rights reserved.
//

@protocol FakeWebDataTransferDelegate;

@interface FakeWebDataFixture : NSObject

@property (nonatomic, assign) id <FakeWebDataTransferDelegate> delegate;

// NOTE: the file used should not be to long or else the math will become incorrect.
@property (nonatomic, strong) NSString* readFromDataPath;

@property (nonatomic, assign) NSTimeInterval downloadDuration;
@property (nonatomic, assign) uint64_t processEveryMS;

@property (nonatomic, readonly) BOOL isProcessing;
@property (nonatomic, readonly) float downloadPercentage;
@property (nonatomic, readonly) unsigned long long bytesRead;
@property (nonatomic, readonly) unsigned long long sizeOfFile;

@property (nonatomic, strong) NSString* writeToDataPath;

- (void)start;
- (void)stop;


+ (FakeWebDataFixture*)fixtureForRequest:(id)request;
+ (void)storeFixture:(FakeWebDataFixture*)fixture forRequest:(id)request;
+ (void)removeFixtureForRequest:(id)request;
@end

@protocol FakeWebDataTransferDelegate <NSObject>
@optional
- (void)dataTransferStarted:(FakeWebDataFixture *)transfer;
- (void)dataTransfer:(FakeWebDataFixture*)transfer dataChunk:(NSData*)data;
- (void)dataTransferDone:(FakeWebDataFixture *)transfer;
- (void)dataTransferDidCancel:(FakeWebDataFixture *)transfer;
@end