//
//  BatchLogger.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

@protocol BatchLoggerDelegate <NSObject>

- (void)logWithMessage:(nonnull NSString*)message;

@end
