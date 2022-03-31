//
//  BATrackerSignpostHelper.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BATrackerSignpostHelper.h>

#import <os/log.h>

#import <os/signpost.h>

#import <Batch/BAJson.h>
#import <Batch/BALogger.h>

@implementation BATrackerSignpostHelper {
    os_log_t _log;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if ([BALogger internalLogsEnabled]) {
            _log = os_log_create("com.batch.ios.event-tracker", "BatchEventTracker");
        } else {
            _log = OS_LOG_DISABLED;
        }
    }
    return self;
}

- (void)trackEvent:(NSString *)event withParameters:(NSDictionary *)parameters collapsable:(BOOL)collapsable {
    if (!os_signpost_enabled(_log)) {
        return;
    }

    NSString *jsonParams;
    jsonParams = [BAJson serialize:parameters error:nil];

    if (jsonParams == nil) {
        jsonParams = @"nil";
    }

    os_signpost_event_emit(_log, OS_SIGNPOST_ID_EXCLUSIVE, "Event tracked",
                           "Name: \"%{public}@\", Parameters: %{public}@, Collapsable?: %{public}s", event, jsonParams,
                           collapsable ? "YES" : "NO");
}

// Add webservice reporting?

@end
