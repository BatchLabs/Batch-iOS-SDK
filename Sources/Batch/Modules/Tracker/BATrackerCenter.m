//
//  BATrackerCenter.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAConcurrentQueue.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BAEventSQLiteDatasource.h>
#import <Batch/BAEventSQLiteHelper.h>
#import <Batch/BALocalCampaignsCenter.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BAOSHelper.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAParameter.h>
#import <Batch/BAQueryWebserviceClient.h>
#import <Batch/BARandom.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BATrackerSignpostHelper.h>
#import <Batch/BatchEventDataPrivate.h>

#import <os/log.h>

#define DEBUG_DOMAIN @"Tracking"

#define LOCATION_UPDATE_MINIMUM_TIME_MS 30000

@interface BATrackerCenter () {
    id<BAEventDatasourceProtocol> _datasource;
    BATrackerScheduler *_scheduler;
    dispatch_queue_t _dispatchQueue;
    BAConcurrentQueue *_memoryQueue;
    NSDate *_lastTrackedLocationTimestamp;
    BAOptOut *_optOutModule;
    id<BATrackerSignpostHelperProtocol> _signpostHelper;

    BOOL _flushing;
    BOOL _started;
}

@property (atomic) NSString *flushHash;

@end

@implementation BATrackerCenter

#pragma mark -
#pragma mark Public methods

+ (void)batchWillStart {
    if ([BATrackerCenter currentMode] == BATrackerModeOFF) {
        return;
    }

    // This prevent the tracker to be subscribe many times to the events in case the developper call `startWithAPIKey:`
    // many times.
    if (![[BACoreCenter instance].status isRunning]) {
        [[BATrackerCenter instance] start];
    }
}

+ (void)trackPublicEvent:(nonnull NSString *)name
                   label:(nullable NSString *)label
                    data:(nullable BatchEventData *)data {
    [[BATrackerCenter instance] trackPublicEvent:name label:label data:data];
}

+ (void)trackPrivateEvent:(nonnull NSString *)name parameters:(nullable NSDictionary *)parameters {
    [[BATrackerCenter instance] trackPrivateEvent:name parameters:parameters collapsable:NO];
}

+ (void)trackPrivateEvent:(nonnull NSString *)name
               parameters:(nullable NSDictionary *)parameters
              collapsable:(BOOL)collapsable {
    [[BATrackerCenter instance] trackPrivateEvent:name parameters:parameters collapsable:collapsable];
}

+ (void)trackManualPrivateEvent:(nonnull BAEvent *)event {
    [[BATrackerCenter instance] trackManualPrivateEvent:event];
}

+ (void)trackLocation:(nonnull CLLocation *)location {
    [[BATrackerCenter instance] trackLocation:location];
}

+ (id<BAEventDatasourceProtocol>)datasource {
    return [[BATrackerCenter instance] datasource];
}

+ (BATrackerScheduler *)scheduler {
    return [[BATrackerCenter instance] scheduler];
}

+ (BATrackerCenter *)instance {
    static BATrackerCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BATrackerCenter alloc] init];
    });

    return sharedInstance;
}

+ (BATrackerMode)currentMode {
    NSNumber *mode = [BAParameter objectForKey:kParametersTrackerStateKey fallback:kParametersTrackerStateValue];

    if ([mode isEqualToNumber:@0]) {
        return BATrackerModeOFF;
    } else if ([mode isEqualToNumber:@1]) {
        return BATrackerModeDB_ONLY;
    } else {
        return BATrackerModeON;
    }
}

#pragma mark -
#pragma mark Instance methods

- (instancetype)init {
    self = [super init];
    if ([BANullHelper isNull:self]) {
        return self;
    }

    _datasource = [[BAEventSQLiteDatasource alloc] initWithFilename:@"ba_tr.db" forDBHelper:[BAEventSQLiteHelper new]];

    // Cannot build an event tracker without its storage.
    if ([BANullHelper isNull:_datasource]) {
        return nil;
    }

    _scheduler = [[BATrackerScheduler alloc] init];
    _dispatchQueue = dispatch_queue_create("com.batch.ios.tr", NULL);
    _memoryQueue = [[BAConcurrentQueue alloc] init];
    _flushing = NO;
    _started = NO;
    _optOutModule = [BAOptOut instance];

    if (@available(iOS 12.0, *)) {
        _signpostHelper = [BATrackerSignpostHelper new];
    }

    return self;
}

- (void)dealloc {
    // We need to dispatch_release for iOS 5 devices. If we don't set the variable to NULL we crash on iOS 6+ devices.
    if (_dispatchQueue) {
        _dispatchQueue = NULL;
    }

    [[BANotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Private methods

- (void)start {
    // Cleanup the event states when we start
    dispatch_async(_dispatchQueue, ^{
      // Remove events exceding a limit.
      NSNumber *limit = [BAParameter objectForKey:kParametersTrackerDBLimitKey fallback:kParametersTrackerDBLimitValue];
      if (![BANullHelper isNull:limit]) {
          [[self datasource] deleteEventsOlderThanTheLast:[limit unsignedIntegerValue]];
      }

      [[self datasource] updateEventsStateFrom:BAEventStateAll to:BAEventStateOld];
    });
    _started = YES;

    // Subscribe to Batch runtime events.
    [[BANotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(optOutValueDidChange:)
                                                 name:kBATOptOutChangedNotification
                                               object:nil];
}

- (void)optOutValueDidChange:(NSNotification *)notification {
    if ([@(true) isEqualToNumber:[notification.userInfo objectForKey:kBATOptOutWipeDataKey]]) {
        [BALogger debugForDomain:@"BATrackerCenter" message:@"Wiping user data"];
        [self deleteAllEvents];
    }
}

- (id<BAEventDatasourceProtocol>)datasource {
    return _datasource;
}

- (BATrackerScheduler *)scheduler {
    return _scheduler;
}

- (void)trackPublicEvent:(nonnull NSString *)name
                   label:(nullable NSString *)label
                    data:(nullable BatchEventData *)data {
    name = [@"E." stringByAppendingString:name];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:4];
    if ([label isKindOfClass:[NSString class]]) {
        if (label.length > 200) {
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"Event label is too long, removing it."];
        } else {
            parameters[BA_PUBLIC_EVENT_KEY_LABEL] = label;
        }
    }

    if ([data isKindOfClass:[BatchEventData class]]) {
        [parameters addEntriesFromDictionary:[data _internalDictionaryRepresentation]];
    }

    if ([self internalTrackEvent:name withParameters:parameters collapsable:false]) {
        [[BALocalCampaignsCenter instance] processTrackerPublicEventNamed:name label:label data:data];
    }
}

- (void)trackPrivateEvent:(nonnull NSString *)name
               parameters:(nullable NSDictionary *)parameters
              collapsable:(BOOL)collapsable {
    if ([self internalTrackEvent:name withParameters:parameters collapsable:collapsable]) {
        [[BALocalCampaignsCenter instance] processTrackerPrivateEventNamed:name];
    }
}

- (void)trackManualPrivateEvent:(nonnull BAEvent *)event {
    if ([self internalTrackEvent:event]) {
        [[BALocalCampaignsCenter instance] processTrackerPrivateEventNamed:event.name];
    }
}

- (void)trackLocation:(nonnull CLLocation *)location {
    if (location == nil) {
        return;
    }

    NSDate *currentDate = [NSDate date];

    // See if a location update should be sent.
    BOOL shouldTrackLocation = NO;

    if (_lastTrackedLocationTimestamp == nil) {
        [BALogger debugForDomain:DEBUG_DOMAIN
                         message:@"Tracking location because no previous location has been tracked"];
        shouldTrackLocation = YES;
    } else if ([currentDate timeIntervalSinceDate:_lastTrackedLocationTimestamp] * 1000 >=
               LOCATION_UPDATE_MINIMUM_TIME_MS) {
        [BALogger
            debugForDomain:DEBUG_DOMAIN
                   message:
                       @"Tracking location because the minimum time interval since the last sent update has passed"];
        shouldTrackLocation = YES;
    }

    // Yes this could have been a big "if", but it would have been less readable
    if (!shouldTrackLocation) {
        [BALogger debugForDomain:DEBUG_DOMAIN message:@"Ignoring location track"];
        return;
    }

    // According to the doc, if horizontalAccuracy is negative, it's an invalid location
    // Don't bother sending it
    if (location.horizontalAccuracy < 0) {
        return;
    }

    NSDate *systemTs = location.timestamp;
    id timestamp;
    if (systemTs == nil) {
        timestamp = [NSNull null];
    } else {
        timestamp = [NSNumber numberWithDouble:floor([systemTs timeIntervalSince1970] * 1000)];
    }

    NSDictionary *params = @{
        @"lat" : [NSNumber numberWithDouble:location.coordinate.latitude],
        @"lng" : [NSNumber numberWithDouble:location.coordinate.longitude],
        @"acc" : [NSNumber numberWithDouble:location.horizontalAccuracy],
        @"date" : timestamp
    };

    [self trackPrivateEvent:@"_LOCATION_CHANGED" parameters:params collapsable:YES];

    _lastTrackedLocationTimestamp = currentDate;
}

/**
 Underlying method that should never be called directly

 Returns whether further processing of the event should continue (true) or be interrupted (false)
 */
- (BOOL)internalTrackEvent:(NSString *)name withParameters:(NSDictionary *)parameters collapsable:(BOOL)collapsable {
    BAEvent *event;
    if (collapsable) {
        event = [BACollapsableEvent eventWithName:name andParameters:parameters];
    } else {
        event = [BAEvent eventWithName:name andParameters:parameters];
    }

    return [self internalTrackEvent:event];
}

/**
 Underlying method that should never be called directly

 Returns whether further processing of the event should continue (true) or be interrupted (false)
 */
- (BOOL)internalTrackEvent:(BAEvent *)event {
    BOOL collapsable = [event isKindOfClass:[BACollapsableEvent class]];
    NSString *name = event.name;
    NSDictionary *parameters = event.parametersDictionary;

    [_signpostHelper trackEvent:name withParameters:parameters collapsable:collapsable];

    if ([BATrackerCenter currentMode] == BATrackerModeOFF) {
        return false;
    }

    if ([_optOutModule isOptedOut]) {
        [BALogger errorForDomain:@"Batch.User" message:@"Batch is opted out from: refusing to track event"];
    }

    [BALogger debugForDomain:NSStringFromClass([self class])
                     message:@"Tracking event: %@ with parameters: %@", name, [parameters description]];

    [_memoryQueue push:event];

    [self flush];

    return true;
}

- (void)flush {
    if (_started && _dispatchQueue && _memoryQueue && _datasource) {
        // Create a hash. If hash hasn't changed when executing block, proceed.
        NSString *hash = [BARandom randomAlphanumericStringWithLength:10];
        self.flushHash = hash;

        // Dispatch after 1 second to allow more events to be enqueued.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), _dispatchQueue, ^{
          if (![self.flushHash isEqualToString:hash]) {
              // Instance's flush hash has changed since block was enqueued. Don't need to continue.
              return;
          }

          self->_flushing = YES;
          while (![self->_memoryQueue empty]) {
              BAEvent *event = (BAEvent *)[self->_memoryQueue poll];
              if (event == nil || ![self->_datasource addEvent:event]) {
                  [BALogger debugForDomain:DEBUG_DOMAIN message:@"Failed to add event: %@", event];
              }
          }

          [self->_scheduler newEventsAvailable];
          self->_flushing = NO;
        });
    }
}

- (BAConcurrentQueue *)queue {
    return _memoryQueue;
}

- (void)stop {
    _started = NO;
}

- (void)deleteAllEvents {
    [_memoryQueue clear];
    dispatch_async(_dispatchQueue, ^{
      [self->_datasource clear];
    });
}

@end
