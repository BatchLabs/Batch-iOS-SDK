#import <Batch/BALoggerUnified.h>

#import <os/log.h>

@interface BALoggerUnified ()
{
    os_log_t _coreLogObject;
    os_log_t _internalLogObject;
}
@end

@implementation BALoggerUnified

- (instancetype)init
{
    self = [super init];
    if (self) {
        _coreLogObject = os_log_create("com.batch.ios", "Batch");
        _internalLogObject = os_log_create("com.batch.ios.internal", "Batch-Internal");
    }
    return self;
}

- (void)logMessage:(NSString *)message subsystem:(NSString *)subsystem internal:(BOOL)internal
{
    if ((!internal && _coreLogObject == nil) ||
        (internal && _internalLogObject == nil)) {
        NSLog(@"[%@] - %@%@", internal ? @"Batch-Internal" : @"Batch", subsystem, message);
        return;
    }
    
    if (subsystem == nil) {
        subsystem = @"";
    }
    
    if (message == nil) {
        return;
    }
    
    os_log(internal ? _internalLogObject : _coreLogObject, "%{public}s%{public}s", [subsystem cStringUsingEncoding:NSUTF8StringEncoding], [message cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end
