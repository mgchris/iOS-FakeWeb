//
//  FakeWebResponder.h
//  FakeWeb
//
//  Created by Toshirhio Morimoto on 2/13/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import <Foundation/Foundation.h>

@class FakeWebDataFixture;
@interface FakeWebResponder : NSObject {
    NSString        *_uri;
    NSString        *_method;
    NSString        *_body;
    NSString        *_statusMessage;
    int             _status;
    
    NSTimeInterval  _delay;
    NSError         *_error;
    NSString        *_dataPath;
    NSTimeInterval  _downloadDuration;
    BOOL            _useDataFixture;
}

@property (nonatomic, strong) NSString *uri;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSString *statusMessage;
@property (nonatomic) int status;
@property (nonatomic) BOOL useDataFixture;

// MG
@property (nonatomic) NSTimeInterval delay;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) NSString *dataPath;
@property (nonatomic) NSTimeInterval downloadDuration;


+ (FakeWebDataFixture*)buildFixtureForResponder:(FakeWebResponder*)responder;
-(id) initWithUri:(NSString *)uri method:(NSString *)method body:(NSString *)body status:(NSInteger)status statusMessage:(NSString *)statusMessage;

@end
