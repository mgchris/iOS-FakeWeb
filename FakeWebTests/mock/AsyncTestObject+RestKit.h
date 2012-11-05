//
//  AsyncTestObject+RestKit.h
//  FakeWeb
//
//  Created by Chris Evans on 11/5/12.
//  Copyright (c) 2012 Toshihiro Morimoto (id:dealforest). All rights reserved.
//

#import "AsyncTestObject.h"
#import <RestKit/RKRequest.h>

@interface AsyncTestObject (RestKit) <RKRequestDelegate>

@end
