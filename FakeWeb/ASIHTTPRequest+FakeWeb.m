//
//  ASIHTTPRequest+FakeWeb.m
//  FakeWeb
//
//  Created by Toshirhio Morimoto on 5/15/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import "ASIHTTPRequest+FakeWeb.h"
#import "FakeWeb.h"
#import "FakeWeb+Private.h"
#import <objc/runtime.h> 
#import <objc/message.h>

void Swizzle(Class c, SEL orig, SEL new);

@implementation ASIHTTPRequest (FakeWeb)

+ (void)load
{
    Class c = [ASIHTTPRequest class];
    Swizzle(c, @selector(startSynchronous), @selector(overrideStartSynchronous));
    Swizzle(c, @selector(startAsynchronous), @selector(overrideStartAsynchronous));
    Swizzle(c, @selector(responseStatusCode), @selector(overrideResponseStatusCode));
    Swizzle(c, @selector(responseStatusMessage), @selector(overrideResponseStatusMessage));
    Swizzle(c, @selector(responseString), @selector(overrideResponseString));
    Swizzle(c, @selector(responseData), @selector(overrideResponseData));
}

-(void) overrideStartSynchronous
{
    FakeWebResponder *responder = [FakeWeb responderFor:[self.url absoluteString] method:self.requestMethod];
    if (responder)
        return;
        
    [self overrideStartSynchronous];
}

-(void) overrideStartAsynchronous
{
    FakeWebResponder *responder = [FakeWeb responderFor:[self.url absoluteString] method:self.requestMethod];
    if (responder)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0001), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			dispatch_async( dispatch_get_main_queue(), ^{
				completionBlock();
			});
		});
    }
    else 
    {
        [self overrideStartAsynchronous];
    }
}

- (NSInteger)overrideResponseStatusCode 
{
    FakeWebResponder *responder = [FakeWeb machingResponder];
    if (responder)
    {
        return [responder status];
    }
    return [self overrideResponseStatusCode];
}

- (NSString *)overrideResponseStatusMessage
{
    FakeWebResponder *responder = [FakeWeb machingResponder];
    if (responder)
    {
        return [responder statusMessage];
    }
    return [self overrideResponseStatusMessage];
}

- (NSString *)overrideResponseString
{
    FakeWebResponder *responder = [FakeWeb machingResponder];
    if (responder)
    {
        return [responder body];
    }
    return [self overrideResponseString];
}

- (NSData *) overrideResponseData 
{
    NSString *responseString = [self overrideResponseString];
    return [responseString dataUsingEncoding:NSUTF8StringEncoding];
}

/*
 * see http://stackoverflow.com/questions/1637604/method-swizzle-on-iphone-device
 */

void Swizzle(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}

@end