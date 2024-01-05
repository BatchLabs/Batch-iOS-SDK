#import <Batch/BatchLogger.h>
#import <Foundation/Foundation.h>
#import <os/log.h>

@protocol BALoggerProtocol <NSObject>

- (void)logMessage:(NSString *)message
         subsystem:(NSString *)subsystem
          internal:(BOOL)internal
             level:(os_log_type_t)level;

@end

@protocol BALoggerDelegateSource <NSObject>

@property (nonatomic, readonly) id<BatchLoggerDelegate> loggerDelegate;

@end
