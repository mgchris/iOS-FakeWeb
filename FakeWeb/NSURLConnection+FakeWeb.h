//
//  NSURLConnection+FakeWeb.h
//  FakeWeb
//
//  Created by Toshirhio Morimoto on 12/06/25.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import <Foundation/Foundation.h>
@class FakeWebResponder;

@interface NSURLConnection (FakeWeb)

+ (NSHTTPURLResponse *)createDummyResponse:(NSURLRequest *)request responder:(FakeWebResponder *)responder;

@end
