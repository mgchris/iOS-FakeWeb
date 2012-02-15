//
//  FakeWeb.m
//  FakeWeb
//
//  Created by Toshihiro Morimoto on 2/8/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import "FakeWeb.h"

static NSMutableDictionary *uriMap;
static NSMutableDictionary *passthroughUriMap;
static NSMutableDictionary *raiseExceptionUriMap;
static BOOL allowNetConnect;
static BOOL finishedInitialized;

@interface FakeWeb(Private)
+(FakeWebResponder*) uriMapMatches:(NSMutableDictionary*)map uri:(NSString*)uri method:(NSString*)method type:(NSString*)type;
+(NSString*) normalizeUri:(NSString*)uri;
+(NSString*) sortQuery:(NSString*)uri;
@end

@implementation FakeWeb

+ (void) initialize {
    uriMap = [NSMutableDictionary dictionary];
    passthroughUriMap = [NSMutableDictionary dictionary];
    raiseExceptionUriMap = [NSMutableDictionary dictionary];
    allowNetConnect = TRUE;
    finishedInitialized = TRUE;
}

+ (NSString*) keyForUri:(NSString*)uri method:(NSString*)method {
    return [NSString stringWithFormat:@"%@ %@", method, [FakeWeb normalizeUri:uri]];
}

+(void) registerUri:(NSString*)uri method:(NSString*)method body:(NSString*)body staus:(int)status statusMessage:(NSString*)statusMessage {
    NSArray *url  = [uri componentsSeparatedByString:@"?"];
    NSString *key = [FakeWeb keyForUri:[url objectAtIndex:0] method:method];
    FakeWebResponder *responder = [[FakeWebResponder alloc] initWithUri:uri method:method status:status statusMessage:statusMessage];
    [uriMap setValue:responder forKey:key];
}

+(void) registerUri:(NSString*)uri method:(NSString*)method body:(NSString*)body staus:(int)status {
    [FakeWeb registerUri:uri method:method body:body staus:status statusMessage:nil];
}

+(void) registerUri:(NSString*)uri method:(NSString*)method body:(NSString*)body {
    [FakeWeb registerUri:uri method:method body:body staus:200 statusMessage:nil];
}



+(BOOL) registeredUri:(NSString*)uri {
    return [FakeWeb registeredUri:uri method:@"ANY"];
}

+(BOOL) registeredUri:(NSString*)uri method:(NSString*)method {
    NSArray *url  = [uri componentsSeparatedByString:@"?"];
    NSString *key = [FakeWeb keyForUri:[url objectAtIndex:0] method:method];
    return [uriMap objectForKey:key] ? TRUE : FALSE;
}



+(void) registerPassthroughUri:(NSString*)uri {
    [FakeWeb registerPassthroughUri:uri method:@"ANY"];
}

+(void) registerPassthroughUri:(NSString*)uri method:(NSString*)method {
    NSString *key = [FakeWeb keyForUri:uri method:method];
    [passthroughUriMap setValue:[NSString stringWithFormat:@"%d", TRUE] forKey:key];
}

+(BOOL) registeredPassthroughUri:(NSString*)uri {
    return [FakeWeb registeredPassthroughUri:uri method:@"ANY"];
}

+(BOOL) registeredPassthroughUri:(NSString*)uri method:(NSString*)method{
    NSString *key = [FakeWeb keyForUri:uri method:method];
    return [passthroughUriMap objectForKey:key] ? TRUE : FALSE;
}



+(void) raiseNetConnectException:(NSURL*)uri {
    [FakeWeb raiseNetConnectException:uri method:@"ANY"];
}

+(void) raiseNetConnectException:(NSURL*)uri method:(NSString*)method {
    NSArray *url  = [uri componentsSeparatedByString:@"?"];
    NSString *key = [FakeWeb keyForUri:[url objectAtIndex:0] method:method];
    [raiseExceptionUriMap setValue:[NSString stringWithFormat:@"%d", TRUE] forKey:key];
}

+(FakeWebResponder*) responderFor:(NSString*)uri method:(NSString*)method {
    NSArray *url  = [uri componentsSeparatedByString:@"?"];
    
    FakeWebResponder *responder;
    responder = [FakeWeb uriMapMatches:uriMap uri:uri method:method type:@"URI"];
    if (responder) return responder;
    
    responder = [FakeWeb uriMapMatches:uriMap uri:uri method:@"ANY" type:@"URI"];
    if (responder) return  responder;
    
    responder = [FakeWeb uriMapMatches:uriMap uri:uri method:method type:@"REGEX"];
    if (responder) return responder;
    
    responder = [FakeWeb uriMapMatches:uriMap uri:uri method:@"ANY" type:@"REGEX"];
    return responder;
}

+(BOOL) allowNetConnet {
    return allowNetConnect;
}

+(BOOL) setAllowNetConnet:(BOOL)isConnect {
    allowNetConnect = isConnect;
    return [FakeWeb allowNetConnet];
}

+(void) cleanRegistry {
    [uriMap removeAllObjects];
    [passthroughUriMap removeAllObjects];
    [raiseExceptionUriMap removeAllObjects];
}

//--------------------------------------------------------------//
#pragma mark -- Private --
//--------------------------------------------------------------//

+(FakeWebResponder*) uriMapMatches:(NSMutableDictionary*)map uri:(NSString*)uri method:(NSString*)method type:(NSString*)type {
    NSString *key = [FakeWeb keyForUri:uri method:method];
    if ([type isEqualToString:@"URI"]) {
        return [map objectForKey:key];
    }
    else {
        NSArray *allKeys = [map allKeys];
        for (int i = 0; i < [allKeys count]; i++) {
            NSString *uri_ = [[[allKeys objectAtIndex:i] componentsSeparatedByString:@" "] objectAtIndex:1];
            NSString *key_ = [FakeWeb keyForUri:uri_ method:method];
            NSError *error;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:key_
                                                                                   options:NSRegularExpressionCaseInsensitive 
                                                                                     error:&error];
            if (error) return nil;
            if ([regex numberOfMatchesInString:key options:0 range:NSMakeRange(0, [key length])] > 0) {
                return [uriMap objectForKey:key_];
            }
        }
    }
    return nil;
}

+(NSString*) normalizeUri:(NSString*)uri {
    return [uri lowercaseString];
}

+(NSString*) sortQuery:(NSString *)uri {
    NSArray *url = [uri componentsSeparatedByString:@"?"];
    if ([url objectAtIndex:1]) {
    }
    return uri;
}

@end
