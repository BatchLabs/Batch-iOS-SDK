//
//  BALocalCampaignsCenter.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BALocalCampaignsCenter.h>

#import <Batch/BALocalCampaignCountedEvent.h>
#import <Batch/BALocalCampaignsParser.h>
#import <Batch/BALocalCampaignsSQLTracker.h>
#import <Batch/BALogger.h>
#import <Batch/BAMessagingCenter.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAParameter.h>
#import <Batch/BASecureDateProvider.h>
#import <Batch/BASessionManager.h>
#import <Batch/BAThreading.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BatchEventAttributes.h>
#import <Batch/BatchMessagingPrivate.h>

#import <Batch/BALocalCampaignsFilePersistence.h>
#import <Batch/BALocalCampaignsPersisting.h>

#import <Batch/BAEventTrackedSignal.h>
#import <Batch/BANewSessionSignal.h>
#import <Batch/BAPublicEventTrackedSignal.h>

#import <Batch/BALocalCampaignsService.h>
#import <Batch/BAQueryWebserviceClient.h>
#import <Batch/BAWebserviceClientExecutor.h>

#import <Batch/BAInjection.h>

#define LOGGER_DOMAIN @"BALocalCampaignsCenter"

#define CACHE_EXPIRATION_DELAY 15 * 86400 // 15 Days

@interface BALocalCampaignsCenter () {
    NSMutableArray<id<BALocalCampaignSignalProtocol>> *_signalQueue;
    BALocalCampaignsManager *_campaignManager;
    BALocalCampaignsTracker *_viewTracker;
    id<BALocalCampaignsPersisting> _campaignPersister;
    id<BADateProviderProtocol> _dateProvider;

    // Did we already load (or are currently loading) the campaign cache?
    BOOL _didLoadCampaignCache;

    // Are we ready to process signals? Meaning, local campaigns have been synchronized from server.
    BOOL _isReady;

    // Whether we are waiting for the end of JIT sync.
    BOOL _isWaitingJITSync;

    // Dispatch queue to process signals (serial queue)
    dispatch_queue_t _dispatchSignalQueue;
}

@end

@implementation BALocalCampaignsCenter

+ (void)batchWillStart {
    // Warm up the instance so it listens to kNotificationBatchStarts
    [BALocalCampaignsCenter instance];
}

+ (instancetype)instance {
    static BALocalCampaignsCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BALocalCampaignsCenter alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _viewTracker = [BALocalCampaignsTracker new];
    _dateProvider = [BASecureDateProvider new];
    _campaignManager = [[BALocalCampaignsManager alloc] initWithDateProvider:_dateProvider viewTracker:_viewTracker];
    _campaignPersister = [BAInjection injectProtocol:@protocol(BALocalCampaignsPersisting)];
    _signalQueue = [NSMutableArray new];
    _isReady = false;
    _didLoadCampaignCache = false;
    _globalMinimumDisplayInterval = 60;

    _dispatchSignalQueue = dispatch_queue_create("com.batch.localcampaigns.signals", DISPATCH_QUEUE_SERIAL);

    // Setting serial queue with high priority
    dispatch_set_target_queue(_dispatchSignalQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));

    _persistenceQueue = dispatch_queue_create_with_target("com.batch.localcampaigns.persistence", DISPATCH_QUEUE_SERIAL,
                                                          dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));

#if TARGET_OS_VISION
    [BALogger debugForDomain:LOGGER_DOMAIN
                     message:@"Not registering Local Campaigns refresh: unsupported on visionOS."];
    return;
#else
    // New session is used to load the campaign cache, scheduling server refreshs
    // and emitting BANewSessionSignal
    [[BANotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newSessionStartedNotification)
                                                 name:BATNewSessionStartedNotification
                                               object:nil];
#endif
}

- (BALocalCampaignsManager *)campaignManager {
    return _campaignManager;
}

- (id<BALocalCampaignsPersisting>)campaignPersister {
    return _campaignPersister;
}

- (BALocalCampaignsTracker *)viewTracker {
    return _viewTracker;
}

- (void)emitSignal:(id<BALocalCampaignSignalProtocol>)signal {
#if TARGET_OS_VISION
    [BALogger debugForDomain:LOGGER_DOMAIN message:@"Not handling Local Campaigns signal: unsupported on visionOS."];
    return;
#else
    if ([[BAOptOut instance] isOptedOut]) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Batch is opted-out from, not bubbling local campaigns signal"];
        return;
    }

    if (signal == nil) {
        return;
    }

    if (!_isReady) {
        [BALogger debugForDomain:LOGGER_DOMAIN
                         message:@"Local Campaign module isn't ready, enqueueing signal: %@", signal];
        [self enqueueSignal:signal];
        return;
    }

    // Skip processing the signal if the event is not watched to avoid useless work
    if ([signal isKindOfClass:BAEventTrackedSignal.class]) {
        BAEventTrackedSignal *eventTrackedSignal = (BAEventTrackedSignal *)signal;
        if (![_campaignManager isEventWatched:eventTrackedSignal.name]) {
            return;
        }
    }
    if ([signal isKindOfClass:BAPublicEventTrackedSignal.class]) {
        BAPublicEventTrackedSignal *eventTrackedSignal = (BAPublicEventTrackedSignal *)signal;
        if (![_campaignManager isEventWatched:eventTrackedSignal.name]) {
            return;
        }
    }

    if ([self->_campaignManager isOverGlobalCappings]) {
        return;
    }

    dispatch_async(_dispatchSignalQueue, ^{
      if (self->_isWaitingJITSync) {
          [BALogger debugForDomain:LOGGER_DOMAIN message:@"JIT sync in progress, enqueueing signal: %@", signal];
          [self enqueueSignal:signal];
      } else {
          [self electCampaignForSignal:signal];
      }
    });
#endif
}

/**
 * Elect the right campaign for a given signal and display it.
 *
 *  Election process is the following :
 *  - Get all eligible campaigns sorted by priority for a signal:
 *      - If no eligible campaigns found:
 *          Do nothing
 *      - Else: Look if the first one is requiring a JIT sync :
 *          - Yes: Check if we need to make a new JIT sync (meaning last call older than  MIN_DELAY_BETWEEN_JIT_SYNC)
 *              - Yes: Check if JIT service is available :
 *                  - Yes: Sync all campaigns requiring a JIT sync limited by MAX_CAMPAIGNS_JIT_THRESHOLD and stopping
 * at the first campaign that not requiring JIT:
 *                      - If server respond with no eligible campaigns :
 *                          - Display the first campaign not requiring a JIT sync (if there's one else do noting)
 *                      - else :
 *                          - Display the first campaign verified by the server
 *                  - No: Display the first campaign not requiring a JIT sync (if there's one else do noting)
 *              -No: Display it
 *          - No: Display it
 */
- (void)electCampaignForSignal:(id<BALocalCampaignSignalProtocol>)signal {
    // Get all eligible campaigns (sorted by priority) regardless of the JIT sync
    NSArray *eligibleCampaigns = [self->_campaignManager eligibleCampaignsSortedByPriority:signal];

    if ([eligibleCampaigns count] > 0) {
        // Get the first elected campaign
        BALocalCampaign *firstElectedCampaign = eligibleCampaigns[0];
        if (firstElectedCampaign.requiresJustInTimeSync) {
            BATSyncedJITCampaignState syncedCampaignState =
                [self->_campaignManager syncedJITCampaignState:firstElectedCampaign];
            if (syncedCampaignState == BATSyncedJITCampaignStateEligible) {
                // Last succeed JIT sync for this campaign is NOT older than 30 sec, considering eligibility up to date.
                [BALogger debugForDomain:LOGGER_DOMAIN
                                 message:@"Skipping JIT sync since this campaign has been already synced recently."];
                [self displayInAppMessage:firstElectedCampaign];

            } else if (syncedCampaignState == BATSyncedJITCampaignStateRequiresSync &&
                       [self->_campaignManager isJITServiceAvailable]) {
                // JIT available, getting all campaigns to sync
                NSArray *eligibleCampaignsRequiringJIT =
                    [self->_campaignManager firstEligibleCampaignsRequiringSync:eligibleCampaigns];
                BALocalCampaign *offlineCampaignFallback =
                    [self->_campaignManager firstCampaignNotRequiringJITSync:eligibleCampaigns];
                self->_isWaitingJITSync = true;
                [self->_campaignManager
                    verifyCampaignsEligibilityFromServer:eligibleCampaignsRequiringJIT
                                          withCompletion:^(BALocalCampaign *_Nullable electedCampaign) {
                                            if (electedCampaign != nil) {
                                                [BALogger
                                                    debugForDomain:LOGGER_DOMAIN
                                                           message:@"Elected campaign has been synchronized with JIT."];
                                                [self displayInAppMessage:electedCampaign];
                                            } else if (offlineCampaignFallback != nil) {
                                                [BALogger debugForDomain:LOGGER_DOMAIN
                                                                 message:@"JIT respond with no eligible campaigns or "
                                                                         @"with error. Fallback on offline campaign."];
                                                [self displayInAppMessage:offlineCampaignFallback];

                                            } else {
                                                [BALogger
                                                    debugForDomain:LOGGER_DOMAIN
                                                           message:@"Ne eligible campaigns found after the JIT sync."];
                                            }
                                            self->_isWaitingJITSync = false;
                                            [self dequeueSignals];
                                          }];

            } else {
                // JIT not available or campaign is cached and not eligible. Fallback on offline campaign
                BALocalCampaign *firstEligibleCampaignNotRequiringJITSync =
                    [self->_campaignManager firstCampaignNotRequiringJITSync:eligibleCampaigns];
                if (firstEligibleCampaignNotRequiringJITSync != nil) {
                    [BALogger debugForDomain:LOGGER_DOMAIN
                                     message:@"JIT not available or campaign already in cached and not eligible, "
                                             @"fallback on offline campaign."];
                    [self displayInAppMessage:firstEligibleCampaignNotRequiringJITSync];
                }
            }
        } else {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Elected campaign not requiring a sync, display it."];
            [self displayInAppMessage:firstElectedCampaign];
        }

    } else {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"No eligible campaigns found."];
    }
}

- (void)displayInAppMessage:(nonnull BALocalCampaign *)campaign {
    //[BALogger debugForDomain:LOGGER_DOMAIN message:@"Campaign %@ found for signal %@", campaign, signal];
    if (campaign.output) {
        [campaign generateOccurrenceIdentifier];
        [campaign.output performForCampaign:campaign];
    } else {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"No output for this campaign. This should not be happening."];
    }
}

- (void)processTrackerPrivateEventNamed:(nonnull NSString *)name {
    [self emitSignal:[[BAEventTrackedSignal alloc] initWithName:name]];
}

- (void)processTrackerPublicEventNamed:(nonnull NSString *)name
                                 label:(nullable NSString *)label
                            attributes:(nullable BatchEventAttributes *)attributes {
    [self emitSignal:[[BAPublicEventTrackedSignal alloc] initWithName:name label:label attributes:attributes]];
}

- (void)didPerformCampaignOutputWithIdentifier:(nonnull NSString *)identifier eventData:(nullable NSObject *)eventData {
    if (identifier == nil) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Can't track local campaign view for a nil identifier"];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      BALocalCampaignCountedEvent *ev =
          [self->_viewTracker trackEventForCampaignID:identifier kind:BALocalCampaignTrackerEventKindView];
      if (ev != nil) {
          [BATrackerCenter trackPrivateEvent:@"_LC_VIEW"
                                  parameters:@{
                                      @"id" : identifier,
                                      @"ed" : eventData != nil ? eventData : @{},
                                      @"count" : @(ev.count),
                                      @"last" : @(floor([ev.lastOccurrence timeIntervalSince1970] * 1000))
                                  }];
      } else {
          [BALogger debugForDomain:LOGGER_DOMAIN
                           message:@"An unknown error occurred while tracking a local campaign view. Not sending the "
                                   @"view to the server."];
      }
    });
}

- (void)enqueueSignal:(id<BALocalCampaignSignalProtocol>)signal {
    // This check should be made before calling this method, but we need to ensure it
    // so that we don't end up in an infinite loop
    if (_isReady && !_isWaitingJITSync) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Cannot enqueue a signal when the SDK is ready."];
        return;
    }
    @synchronized(_signalQueue) {
        if (_isReady && !_isWaitingJITSync) {
            // We became ready while waiting for the lock
            // This means that the events have probably been dequeued in the meantime
            [BALogger debugForDomain:LOGGER_DOMAIN
                             message:@"SDK ready state changed while enqueueing signal: replaying immediatly."];
            [self emitSignal:signal];
        } else {
            [_signalQueue addObject:signal];
        }
    }
}

- (void)dequeueSignals {
    @synchronized(_signalQueue) {
        NSArray *enqueuedSignals = [_signalQueue copy];
        [_signalQueue removeAllObjects];

        if (enqueuedSignals.count > 0) {
            [BALogger debugForDomain:LOGGER_DOMAIN
                             message:@"Replaying %ld local campaign signals", enqueuedSignals.count];
        }

        for (id<BALocalCampaignSignalProtocol> signal in enqueuedSignals) {
            [self emitSignal:signal];
        }
    }
}

- (void)makeReady {
    if (_isReady) {
        return;
    }
    @synchronized(_signalQueue) {
        // This might have changed if makeReady is called concurrently
        if (_isReady) {
            return;
        }
        _isReady = true;
        [self dequeueSignals];
    }
}

- (void)loadCampaigns {
    if (!_didLoadCampaignCache) {
        [self loadCampaignCache];
    } else {
        [self refreshCampaignsFromServer];
    }
}

- (void)loadCampaignCache {
    // Flag this as loaded before we actually do it so that we do not do it twice
    // Setting as ready comes later
    _didLoadCampaignCache = true;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      NSError *err;
      NSArray<BALocalCampaign *> *campaigns;
      BALocalCampaignsGlobalCappings *cappings;
      NSDictionary *rawCampaigns = [self->_campaignPersister loadCampaignsWithError:&err];
      if (rawCampaigns == nil) {
          [BALogger debugForDomain:LOGGER_DOMAIN
                           message:@"Could not load local campaigns from disk. Reason: %@",
                                   err ? err.localizedDescription : @"Unknown error"];
      } else {
          // Ensure cache is not too old
          NSNumber *campaignsCacheTimestamp = [rawCampaigns objectForKey:@"cache_date"];
          if (campaignsCacheTimestamp != nil) {
              if ([campaignsCacheTimestamp doubleValue] + CACHE_EXPIRATION_DELAY <=
                  [[self->_dateProvider currentDate] timeIntervalSince1970]) {
                  [BALogger debugForDomain:LOGGER_DOMAIN message:@"Local campaigns cache is too old, deleting it."];
                  [self->_campaignPersister deleteCampaigns];
                  return;
              }
          }
          campaigns = [BALocalCampaignsParser parseCampaigns:rawCampaigns outPersistable:nil error:&err];
          cappings = [BALocalCampaignsParser parseCappings:rawCampaigns outPersistable:nil];
          if (campaigns == nil) {
              [BALogger errorForDomain:LOGGER_DOMAIN
                               message:@"Could not parse local campaigns loaded from disk: %@",
                                       err ? err.localizedDescription : @"Unknown error"];
          } else {
              [BALogger debugForDomain:LOGGER_DOMAIN
                               message:@"Loaded %lu campaigns from disk", (unsigned long)campaigns.count];
          }
      }
      [self->_campaignManager loadCampaigns:campaigns];
      [self->_campaignManager setCappings:cappings];
      [self campaignCacheReady];
    });
}

- (void)campaignCacheReady {
    // When the cache has been loaded (or attempted to), we can run synchro from server.
    [self refreshCampaignsFromServer];
}

- (void)refreshCampaignsFromServer {
    // Disable signal queue while we are synchronizing local campaigns
    _isReady = false;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [BALogger debugForDomain:LOGGER_DOMAIN message:@"Refreshing local campaigns"];

      NSDictionary<NSString *, BALocalCampaignCountedEvent *> *views =
          [self->_campaignManager viewCountsForLoadedCampaigns];

      BALocalCampaignsServiceDatasource *datasource =
          [[BALocalCampaignsServiceDatasource alloc] initWithViewEvents:views];
      BALocalCampaignsServiceDelegate *delegate =
          [[BALocalCampaignsServiceDelegate alloc] initWithLocalCampaignsCenter:self];

      BAQueryWebserviceClient *ws = [[BAQueryWebserviceClient alloc] initWithDatasource:datasource delegate:delegate];
      [BAWebserviceClientExecutor.sharedInstance addClient:ws];
    });
}

- (void)userDidOptOut {
    // Delete campaigns from disk cache
    [_campaignPersister deleteCampaigns];

    // Clear view tracker and close.
    [_viewTracker clear];
    [_viewTracker close];

    // Reinitialize state
    [self setup];
}

- (void)localCampaignsWebserviceDidFinish {
    [self makeReady];
}

- (void)handleWebserviceResponsePayload:(nonnull NSDictionary *)payload {
    NSError *err = nil;

    NSMutableDictionary *persistPayload = [NSMutableDictionary dictionary];
    NSDictionary *campaignsPayload = nil;
    NSDictionary *cappingsPayload = nil;

    NSArray<BALocalCampaign *> *campaigns = [BALocalCampaignsParser parseCampaigns:payload
                                                                    outPersistable:&campaignsPayload
                                                                             error:&err];
    if (campaigns == nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Could not parse local campaigns webservice response payload: %@",
                                 err ? err.localizedDescription : @"Unknown error"];
        persistPayload = nil;
    } else {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Loaded %ld campaigns from the WS", campaigns.count];
    }

    BALocalCampaignsGlobalCappings *cappings = [BALocalCampaignsParser parseCappings:payload
                                                                      outPersistable:&cappingsPayload];
    if (cappings == nil || (cappings.session == nil && cappings.timeBasedCappings == nil)) {
        cappingsPayload = nil;
    }

    dispatch_async(_persistenceQueue, ^{
      if (campaignsPayload != nil) {
          [persistPayload addEntriesFromDictionary:campaignsPayload];
          if (cappingsPayload != nil) {
              [persistPayload addEntriesFromDictionary:cappingsPayload];
          }
          [persistPayload
              setObject:[NSNumber numberWithDouble:[[self->_dateProvider currentDate] timeIntervalSince1970]]
                 forKey:@"cache_date"];
          [self->_campaignPersister persistCampaigns:persistPayload];
      } else {
          [self->_campaignPersister deleteCampaigns];
      }
    });

    if (err == NULL) {
        [_campaignManager setNextAvailableJITTimestampWithDefaultDelay];
    }

    [_campaignManager loadCampaigns:campaigns];
    [_campaignManager setCappings:cappings];
}

- (void)newSessionStartedNotification {
    // Start loading campaigns (from cache or server)
    [self loadCampaigns];

    // No need to wait for loadCampaigns to finish: the signal will be enqueued
    [self emitSignal:[BANewSessionSignal new]];
}

@end
