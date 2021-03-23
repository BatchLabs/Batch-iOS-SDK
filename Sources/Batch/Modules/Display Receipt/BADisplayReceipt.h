//
//  BADisplayReceipt.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BATMessagePackWriter.h>
#import <Batch/BATMessagePackReader.h>

@interface BADisplayReceipt : NSObject

@property (atomic, assign, readonly) unsigned long long timestamp;
@property (atomic, assign, readwrite) bool replay;
@property (atomic, assign, readwrite) unsigned int sendAttempt;
@property (atomic, copy, readonly, nullable) NSDictionary *od;
@property (atomic, copy, readonly, nullable) NSDictionary *ed;

- (nullable id)initWithTimestamp:(unsigned long long)timestamp
                 replay:(BOOL)replay
            sendAttempt:(unsigned int)sendAttempt
               openData:(nullable NSDictionary *)od
              eventData:(nullable NSDictionary *)ed;
- (BOOL)packToWriter:(nonnull BATMessagePackWriter *)writer error:(NSError * _Nullable * _Nullable)error;
- (nullable NSData *)pack:(NSError * _Nullable * _Nullable)error;

+ (nullable instancetype)unpack:(nonnull NSData *)data error:(NSError * _Nullable * _Nullable)error;

@end
