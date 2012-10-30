//
//  FakeWebResponder.m
//  FakeWeb
//
//  Created by Toshirhio Morimoto on 2/13/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import "FakeWebResponder.h"
#import "FakeWebDataFixture.h"

@implementation FakeWebResponder

@synthesize uri = _uri, method = _method, body = _body, status = _status,  statusMessage = _statusMessage, dataPath = _dataPath, downloadDuration = _downloadDuration;

-(id) initWithUri:(NSString *)uri method:(NSString *)method body:(NSString *)body status:(NSInteger)status statusMessage:(NSString *)statusMessage {
    self = [super init];
    if (self) {
        _uri = uri;
        _method = method;
        _body = body;
        _status = status;
        _statusMessage = statusMessage;
        
        if (!_status)
            _status = 200;
        if (!_statusMessage)
            _statusMessage = @"OK";
        
        _delay = 0.0f;
        _downloadDuration = -1.0f;
    }
    return self;
}

+ (FakeWebDataFixture*)buildFixtureForResponder:(FakeWebResponder*)responder {
    FakeWebDataFixture* fixture = [[FakeWebDataFixture alloc] init];
    fixture.downloadDuration = responder.downloadDuration;
    fixture.readFromDataPath = responder.dataPath;
    return [fixture autorelease];
}

@end
