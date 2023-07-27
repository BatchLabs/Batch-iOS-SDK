//
//  BatchLogger.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

/// Protocol to implement if you want to use ``Batch/Batch/setLoggerDelegate:`` to get Batch logs in a custom object of
/// yours.
///
/// - Important: Be careful with your implementation: using this can impact stability and performance. You should only
/// use it if you know what you are doing.
@protocol BatchLoggerDelegate <NSObject>

/// Delegated method to get Batch logs
///
/// - Parameter message: Batch message
- (void)logWithMessage:(nonnull NSString *)message;

@end
