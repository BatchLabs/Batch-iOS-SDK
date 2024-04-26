//
//  DeeplinkDelegateStub.h
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/Batch.h>
#import <Foundation/Foundation.h>

@interface DeeplinkDelegateStub : NSObject <BatchDeeplinkDelegate>

@property (assign) BOOL hasOpenBeenCalled;

@end
