//
//  AsyncTestObject+RestKit.m
//  FakeWeb
//
//  Created by Chris Evans on 11/5/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import "AsyncTestObject+RestKit.h"

@implementation AsyncTestObject (RestKit)

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    self.request = request;
    self.error = error;
}

- (void)requestDidCancelLoad:(RKRequest *)request
{
    self.request = request;
    self.didCancelProgressDownload = YES;
}

@end
