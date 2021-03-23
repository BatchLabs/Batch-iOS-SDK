//
//  BADisplayReceiptWebserviceClient.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWebserviceMsgPackClient.h>

@interface BADisplayReceiptWebserviceClient : BAWebserviceMsgPackClient <BAConnectionDelegate>

- (nullable instancetype)initWithReceipts:(nonnull NSArray *)receipts
                                  success:(void (^ _Nullable)(void))successHandler
                                    error:(void (^ _Nullable)(NSError* _Nonnull error))errorHandler;

@end
