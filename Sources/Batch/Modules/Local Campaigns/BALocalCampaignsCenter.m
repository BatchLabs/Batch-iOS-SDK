//
//  BALocalCampaignsCenter.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BALocalCampaignsCenter.h>

#import <Batch/BANotificationCenter.h>
#import <Batch/BASecureDateProvider.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BALogger.h>
#import <Batch/BAMessagingCenter.h>
#import <Batch/BAThreading.h>
#import <Batch/BatchMessagingPrivate.h>
#import <Batch/BASessionManager.h>
#import <Batch/BAParameter.h>
#import <Batch/BAOptOut.h>
#import <Batch/BatchEventData.h>
#import <Batch/BALocalCampaignsSQLTracker.h>
#import <Batch/BALocalCampaignsParser.h>
#import <Batch/BALocalCampaignCountedEvent.h>

#import <Batch/BALocalCampaignsPersisting.h>
#import <Batch/BALocalCampaignsFilePersistence.h>

#import <Batch/BACampaignsLoadedSignal.h>
#import <Batch/BAEventTrackedSignal.h>
#import <Batch/BAPublicEventTrackedSignal.h>
#import <Batch/BACampaignsRefreshedSignal.h>
#import <Batch/BANewSessionSignal.h>

#import <Batch/BAQueryWebserviceClient.h>
#import <Batch/BAWebserviceClientExecutor.h>
#import <Batch/BALocalCampaignsService.h>

#import <Batch/BAInjection.h>

#define LOGGER_DOMAIN @"BALocalCampaignsCenter"

@interface BALocalCampaignsCenter ()
{
    NSMutableArray<id<BALocalCampaignSignalProtocol>> *_signalQueue;
    BALocalCampaignsManager *_campaignManager;
    id<BALocalCampaignTrackerProtocol> _viewTracker;
    id<BALocalCampaignsPersisting> _campaignPersister;
    
    // Did we already load (or are currently loading) the campaign cache?
    BOOL _didLoadCampaignCache;
    
    // Are we ready to process signals? Meaning, did we load the campaign cache so that we don't waste
    // signals on an empty list?
    BOOL _isReady;
    
    // Is it the first time we're loading the campaigns from the server?
    BOOL _isFirstRemoteLoad;
}

@end

@implementation BALocalCampaignsCenter

+ (void)batchWillStart
{
    // Warm up the instance so it listens to kNotificationBatchStarts
    [BALocalCampaignsCenter instance];
}

+ (instancetype)instance
{
    static BALocalCampaignsCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BALocalCampaignsCenter alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _viewTracker = [BALocalCampaignsSQLTracker new];
    _campaignManager = [[BALocalCampaignsManager alloc] initWithDateProvider:[BASecureDateProvider new] viewTracker:_viewTracker];
    _campaignPersister = [BAInjection injectProtocol:@protocol(BALocalCampaignsPersisting)];
    _signalQueue = [NSMutableArray new];
    _isReady = false;
    _didLoadCampaignCache = false;
    _isFirstRemoteLoad = true;
    _globalMinimumDisplayInterval = 60;
    
    // New session is used to load the campaign cache, scheduling server refreshs
    // and emitting BANewSessionSignal
    [[BANotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newSessionStartedNotification)
                                                 name:BATNewSessionStartedNotification
                                               object:nil];
}

- (BALocalCampaignsManager*)campaignManager {
    return _campaignManager;
}

- (id<BALocalCampaignsPersisting>)campaignPersister {
    return _campaignPersister;
}

- (void)emitSignal:(id<BALocalCampaignSignalProtocol>)signal {
    if ([[BAOptOut instance] isOptedOut]) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Batch is opted-out from, not bubbling local campaigns signal"];
        return;
    }
    
    if (signal == nil) {
        return;
    }
    
    if (!_isReady) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Local Campaign module isn't ready, enqueueing signal: %@", signal];
        [self enqueueSignal:signal];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BALocalCampaign *campaign = [self->_campaignManager campaignToDisplayForSignal:signal];
        if (campaign != nil) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Campaign %@ found for signal %@", campaign, signal];
            if (campaign.output) {
                [campaign generateOccurrenceIdentifier];
                [campaign.output performForCampaign:campaign];
            } else {
                [BALogger debugForDomain:LOGGER_DOMAIN message:@"No output for this campaign. This should not be happening."];
            }
        }
    });
}

- (void)processTrackerPrivateEventNamed:(nonnull NSString*)name{
    if (![_campaignManager isEventWatched:name]) {
        return;
    }
    
    [self emitSignal:[[BAEventTrackedSignal alloc] initWithName:name]];
}

- (void)processTrackerPublicEventNamed:(nonnull NSString*)name label:(nullable NSString*)label data:(nullable BatchEventData*)data {
    if (![_campaignManager isEventWatched:name]) {
        return;
    }

    [self emitSignal:[[BAPublicEventTrackedSignal alloc] initWithName:name label:label data:data]];
}

- (void)didPerformCampaignOutputWithIdentifier:(nonnull NSString*)identifier eventData:(nullable NSObject*)eventData {
    if (identifier == nil) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Can't track local campaign view for a nil identifier"];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BALocalCampaignCountedEvent *ev = [self->_viewTracker trackEventForCampaignID:identifier kind:BALocalCampaignTrackerEventKindView];
        if (ev != nil) {
            [BATrackerCenter trackPrivateEvent:@"_LC_VIEW"
                                    parameters:@{
                                                 @"id": identifier,
                                                 @"ed": eventData != nil ? eventData : @{},
                                                 @"count": @(ev.count),
                                                 @"last": @(floor([ev.lastOccurrence timeIntervalSince1970] * 1000))
                                                 }];
        } else {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"An unknown error occurred while tracking a local campaign view. Not sending the view to the server."];
        }
    });
}

- (void)enqueueSignal:(id<BALocalCampaignSignalProtocol>)signal {
    // This check should be made before calling this method, but we need to ensure it
    // so that we don't end up in an infinite loop
    if (_isReady) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Cannot enqueue a signal when the SDK is ready."];
        return;
    }
    @synchronized (_signalQueue) {
        if (_isReady) {
            // We became ready while waiting for the lock
            // This means that the events have probably been dequeued in the meantime
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"SDK ready state changed while enqueueing signal: replaying immediatly."];
            [self emitSignal:signal];
        } else {
            [_signalQueue addObject:signal];
        }
    }
}

- (void)dequeueSignals {
    @synchronized (_signalQueue) {
        NSArray *enqueuedSignals = [_signalQueue copy];
        [_signalQueue removeAllObjects];
        
        if (enqueuedSignals.count > 0) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Replaying %ld local campaign signals", enqueuedSignals.count];
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
    @synchronized (_signalQueue) {
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
        [self scheduleCampaignRefreshFromServer];
    }
}

- (void)loadCampaignCache {
    // Flag this as loaded before we actually do it so that we do not do it twice
    // Setting as ready comes later
    _didLoadCampaignCache = true;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *err;
        NSArray<BALocalCampaign*> *campaigns;
        NSDictionary *rawCampaigns = [self->_campaignPersister loadCampaignsWithError:&err];
        if (rawCampaigns == nil) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Could not load local campaigns from disk. Reason: %@", err ? err.localizedDescription : @"Unknown error"];
        } else {
            campaigns = [BALocalCampaignsParser parseCampaigns:rawCampaigns outPersistable:nil error:&err];
            if (campaigns == nil) {
                [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not parse local campaigns loaded from disk: %@", err ? err.localizedDescription : @"Unknown error"];
            } else {
                [BALogger debugForDomain:LOGGER_DOMAIN message:@"Loaded %lu campaigns from disk", (unsigned long)campaigns.count];
            }
        }
        [self->_campaignManager loadCampaigns:campaigns];
        [self campaignCacheReady];
    });
}

- (void)campaignCacheReady {
    // When the cache has been loaded (or attempted to), consider that we're ready
    [self makeReady];
    [self scheduleCampaignRefreshFromServer];
    [self emitSignal:[BACampaignsLoadedSignal new]];
}

- (void)scheduleCampaignRefreshFromServer {
    BOOL didScheduleRefreshInTheFuture = false;
    if (_isFirstRemoteLoad) {
        _isFirstRemoteLoad = false;
        int initialWSDelay = [[BAParameter objectForKey:kParametersLocalCampaignsInitialWSDelayKey fallback:kParametersLocalCampaignsInitialWSDelayValue] intValue];
        if (initialWSDelay > 0) {
            didScheduleRefreshInTheFuture = true;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(initialWSDelay * NSEC_PER_SEC)), dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self refreshCampaignsFromServer];
            });
        }
    }
    
    if (!didScheduleRefreshInTheFuture) {
        [self refreshCampaignsFromServer];
    }
}

- (void)refreshCampaignsFromServer {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Refreshing local campaigns"];
        
        NSDictionary<NSString*, BALocalCampaignCountedEvent*>* views = [self->_campaignManager viewCountsForLoadedCampaigns];
        
        BALocalCampaignsServiceDatasource *datasource = [[BALocalCampaignsServiceDatasource alloc] initWithViewEvents:views];
        BALocalCampaignsServiceDelegate *delegate = [[BALocalCampaignsServiceDelegate alloc] initWithLocalCampaignsCenter:self];
        
        BAQueryWebserviceClient *ws = [[BAQueryWebserviceClient alloc] initWithDatasource:datasource
                                                                                 delegate:delegate];
        [BAWebserviceClientExecutor.sharedInstance addClient:ws];
    });
}

- (void)userDidOptOut {
    // Delete campaigns from disk cache
    [_campaignPersister deleteCampaigns];

    // Reinitialize state
    [self setup];
}

- (void)handleWebserviceResponsePayload:(nonnull NSDictionary*)payload {
    NSError *err = nil;
    NSDictionary *persistPayload = nil;
    
    NSArray<BALocalCampaign*> *campaigns = [BALocalCampaignsParser parseCampaigns:payload outPersistable:&persistPayload error:&err];
    if (campaigns == nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not parse local campaigns webservice response payload: %@", err ? err.localizedDescription : @"Unknown error"];
        persistPayload = nil;
    } else {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Loaded %ld campaigns from the WS", campaigns.count];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if (persistPayload != nil) {
            [self->_campaignPersister persistCampaigns:persistPayload];
        } else {
            [self->_campaignPersister deleteCampaigns];
        }
    });
    
    [_campaignManager loadCampaigns:campaigns];
    [self makeReady];
    [[BALocalCampaignsCenter instance] emitSignal:[BACampaignsRefreshedSignal new]];
}

- (void)newSessionStartedNotification
{
    // No need to wait for loadCampaigns to finish: the signal will be enqueued
    [self emitSignal:[BANewSessionSignal new]];
    [self loadCampaigns];
}

@end
