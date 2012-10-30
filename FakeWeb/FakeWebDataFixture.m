//
//  FakeWebDataTransfer.m
//  FakeWeb
//
//  Copyright (c) 2012 Chris Evans (id:mgChris). All rights reserved.
//

#import "FakeWebDataFixture.h"

@interface FakeWebDataFixture ()


@property (nonatomic) dispatch_source_t transferDispatchSource;
@property (nonatomic, strong) NSDate* startProcessingDate;

dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block);
@end


static NSMutableDictionary* requestFixtures = nil;


#pragma mark -
@implementation FakeWebDataFixture

+ (FakeWebDataFixture*)fixtureForRequest:(id)request
{
    FakeWebDataFixture* fixture = nil;
    
    if( request )
    {
        NSString* key = [NSString stringWithFormat:@"%p", request];
        fixture = [requestFixtures objectForKey:key];
    }
    
    return fixture;
}

+ (void)storeFixture:(FakeWebDataFixture*)fixture forRequest:(id)request
{
    if( requestFixtures == nil )
    {
        requestFixtures = [[NSMutableDictionary alloc] init];
    }
    
    if( request && fixture )
    {
        NSString* key = [NSString stringWithFormat:@"%p", request];
        [requestFixtures setObject:fixture forKey:key];
    }
}

+ (void)removeFixtureForRequest:(id)request
{
    if( request )
    {
        NSString* key = [NSString stringWithFormat:@"%p", request];
        [requestFixtures removeObjectForKey:key];
    }
}

#pragma mark -
- (id)init
{
    self = [super init];
    if (self) {
        _processEveryMS = 100;  // Sends data every 1/10th of a second
    }
    return self;
}

- (void)dealloc
{
    if( self.transferDispatchSource )
    {
        dispatch_release(self.transferDispatchSource);
        self.transferDispatchSource = nil;
    }
    
    [super dealloc];
}


- (void)start
{
    if( self.delegate && [self.readFromDataPath length] > 0 )
    {
        NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:self.readFromDataPath];
        
        if( handle )
        {
            _sizeOfFile = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.readFromDataPath error:nil][NSFileSize] unsignedIntegerValue]; // crazy iOS dictionary call
            _bytesRead = 0;
            self.startProcessingDate = [NSDate date];
            [self updateDownloadPercentage:0.0f];
            if( self.delegate && [self.delegate respondsToSelector:@selector(dataTransferStarted:)] ) {
                [self.delegate dataTransferStarted:self];
            }
            
            NSFileHandle* writeHandle = nil;
            if( self.writeToDataPath )
            {
                // We have a data path to write to
                NSFileManager* fileManager = [[NSFileManager alloc] init];
                [fileManager removeItemAtPath:self.writeToDataPath error:nil]; // just remove it don't bother checking
               
                if( ![fileManager createFileAtPath:self.writeToDataPath contents:[NSData data] attributes:nil] )
                {
                    NSLog(@"Could Not create File at path: %@", self.writeToDataPath);
                }
                
                writeHandle = [NSFileHandle fileHandleForWritingAtPath:self.writeToDataPath];
            }
            
            [self updateProgress:YES];
            self.transferDispatchSource = CreateDispatchTimer(self.processEveryMS, self.processEveryMS / 4, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                if( self.isProcessing )
                {
                    NSDate* currentDate = [NSDate date];
                    NSTimeInterval timePast = [currentDate timeIntervalSinceDate:self.startProcessingDate];
                    NSData* bytes = nil;
                    
                    if( timePast < self.downloadDuration )
                    {
                        // only send the amount of data base on the time left
                        
                        float timeTransferPercentage = timePast / self.downloadDuration;        // A percentage of the data that will be transfer based on the current time.
                        NSUInteger toBeTransferSize = self.sizeOfFile * timeTransferPercentage; // The size that should be transfer with current time.
                        NSUInteger bytesToTransfer = toBeTransferSize - self.bytesRead;
                        
                        bytes = [handle readDataOfLength:bytesToTransfer];
                        _bytesRead += bytesToTransfer;
                    }
                    else if( self.bytesRead != self.sizeOfFile )
                    {
                        // Send the rest of the data in the next stream
                        bytes = [handle readDataToEndOfFile];
                        _bytesRead += [bytes length];
                    }
                    
                    [self updateDownloadPercentage:self.bytesRead / (float)self.sizeOfFile];
                    
                    if( bytes )
                    {
                        [writeHandle writeData:bytes];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if( self.delegate && [self.delegate respondsToSelector:@selector(dataTransfer:dataChunk:)] ) {
                                [self.delegate dataTransfer:self dataChunk:bytes];
                            }
                        });
                    }
                    else if( self.bytesRead == self.sizeOfFile && self.isProcessing) // make sure we are done processing all bytes and we have not been cancelled
                    {
                        // We are done
                        if( self.transferDispatchSource )
                        {
                            dispatch_source_cancel(self.transferDispatchSource);
                            self.transferDispatchSource = nil;
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self updateProgress:NO];
                            if( self.delegate && [self.delegate respondsToSelector:@selector(dataTransferDone:)] ) {
                                [self.delegate dataTransferDone:self];
                            }
                        });
                    }
                }
            });
        }
    }
}

- (void)stop
{
    if( self.isProcessing )
    {
        [self updateProgress:NO];
        
        if( self.transferDispatchSource )
        {
            dispatch_source_cancel(self.transferDispatchSource);
            self.transferDispatchSource = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if( self.delegate && [self.delegate respondsToSelector:@selector(dataTransferDidCancel:)] ) {
                [self.delegate dataTransferDidCancel:self];
            }
        });
        
    }
}

- (void)updateProgress:(BOOL)progress
{
    if( progress != self.isProcessing )
    {
        [self willChangeValueForKey:@"isProgressing"];
        _isProcessing = progress;
        [self didChangeValueForKey:@"isProgressing"];
    }
}

- (void)updateDownloadPercentage:(float)downloaded
{
    if( downloaded != self.downloadPercentage )
    {
        [self willChangeValueForKey:@"downloadPercentage"];
        _downloadPercentage = downloaded;
        [self didChangeValueForKey:@"downloadPercentage"];
    }
}

#pragma mark -
dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}
@end



