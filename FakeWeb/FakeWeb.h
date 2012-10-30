//
//  FakeWeb.h
//  FakeWeb
//
//  Created by Toshihiro Morimoto on 2/8/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FakeWebResponder.h"
#import "FakeWebDataFixture.h"

@interface FakeWeb : NSObject

#pragma mark -
#pragma mark register method

+(void) registerUri:(NSString *)uri method:(NSString *)method rotatingResponse:(NSArray *)rotatingResponses;

+(void) registerUri:(NSString *)uri method:(NSString *)method body:(NSString *)body status:(NSInteger)status statusMessage:(NSString *)statusMessage;
+(void) registerUri:(NSString *)uri method:(NSString *)method body:(NSString *)body status:(NSInteger)status;
+(void) registerUri:(NSString *)uri method:(NSString *)method body:(NSString *)body;

+(void) registerPassthroughUri:(NSString *)uri;
+(void) registerPassthroughUri:(NSString *)uri method:(NSString *)method;


// MG additions
/*!
 *  Wanted to have a error that gets passed
 */
+(void) registerUri:(NSString *)uri method:(NSString *)method body:(NSString *)body staus:(NSInteger)status statusMessage:(NSString *)statusMessage withError:(NSError*)error withResponseDelay:(NSTimeInterval)delay;


//  These methods are used to register asynchronous responses.
/*!
 *  @param delay The amount of time to wait before sending a response.
 */
+(void) registerUri:(NSString *)uri method:(NSString *)method body:(NSString *)body staus:(NSInteger)status statusMessage:(NSString *)statusMessage withResponseDelay:(NSTimeInterval)delay;

/*!
 *  @param dataPath Is the file to return when the user request data from response.
 */
+(void) registerUri:(NSString *)uri method:(NSString *)method staus:(NSInteger)status withResponseDelay:(NSTimeInterval)delay withFileDataPath:(NSString*)dataPath;

/*!
 *  @param useFixture When this is yes the app will use the progress callbacks.
 *  @param duration The amount of time it should take for the download to complete.  If streaming is NO this field is ignored.
 *  @note When using this method it will allow the code to show progress for downloading.
 */
+(void) registerUri:(NSString *)uri method:(NSString *)method staus:(NSInteger)status withFileDataPath:(NSString*)dataPath useDataFixture:(BOOL)useFixture withDownloadDuration:(NSTimeInterval)duration;


#pragma mark -
#pragma mark check method

+(BOOL) registeredPassthroughUri:(NSString *)uri;
+(BOOL) registeredPassthroughUri:(NSString *)uri method:(NSString *)method;

+(BOOL) registeredUri:(NSString *)uri;
+(BOOL) registeredUri:(NSString *)uri method:(NSString *)method;

#pragma mark -
#pragma mark throw exception method

+(void) raiseNetConnectException:(NSString *)uri method:(NSString *)method;

#pragma mark -
#pragma mark option method

+(BOOL) allowNetConnet;
+(BOOL) setAllowNetConnet:(BOOL)isConnect;
+(void) cleanRegistry;

+ (void)cleanUpForRequest:(id)request;

@end
