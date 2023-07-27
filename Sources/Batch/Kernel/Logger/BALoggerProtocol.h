#import <Batch/BatchLogger.h>
#import <Foundation/Foundation.h>

@protocol BALoggerProtocol <NSObject>

- (void)logMessage:(NSString *)message subsystem:(NSString *)subsystem internal:(BOOL)internal;

@end

@protocol BALoggerDelegateSource <NSObject>

@property (nonatomic, readonly) id<BatchLoggerDelegate> loggerDelegate;

@end
