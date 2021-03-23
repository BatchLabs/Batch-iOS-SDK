//
//  BADisplayReceiptCenter.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BACenterMulticastDelegate.h>

@interface BADisplayReceiptCenter : NSObject <BACenterProtocol>

+ (void)send;
- (void)sendIfNonOptout;

@end
