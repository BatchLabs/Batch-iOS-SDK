//
//  DeeplinkDelegateStub.h
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/Batch.h>

@interface DeeplinkDelegateStub: NSObject <BatchDeeplinkDelegate>

@property (assign) BOOL hasOpenBeenCalled;

@end
