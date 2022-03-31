//
//  BATrackerScheduler.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BATrackerScheduler.h>

#import <Batch/BAErrorHelper.h>
#import <Batch/BAParameter.h>
#import <Batch/BAReachabilityHelper.h>
#import <Batch/BAThreading.h>
#import <Batch/BATrackerSender.h>

@interface BATrackerScheduler () {
    BATrackerSender *_sender;
    BOOL _hasNewEvents;
    NSTimer *_retryTimer;
    NSUInteger _initialRetryDelay;
    NSUInteger _maxRetryDelay;
    NSUInteger _currentRetryDelay;
}

@end

@implementation BATrackerScheduler

- (instancetype)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _sender = [BATrackerSender new];
    _hasNewEvents = false;

    _initialRetryDelay = [[BAParameter objectForKey:kParametersTrackerInitialDelayKey
                                           fallback:kParametersTrackerInitialDelayValue] unsignedIntegerValue];
    _maxRetryDelay = [[BAParameter objectForKey:kParametersTrackerMaxDelayKey
                                       fallback:kParametersTrackerMaxDelayValue] unsignedIntegerValue];
    _currentRetryDelay = _initialRetryDelay;

    //    [BAReachabilityHelper reachabilityForInternetConnection];
    [BAReachabilityHelper addObserver:self selector:@selector(reachabilityChanged)];

    return self;
}

- (void)dealloc {
    [self stopTimer];

    [BAReachabilityHelper removeObserver:self];
}

- (void)newEventsAvailable {
    // Don't try to send if we are waiting for a retry
    if (!_retryTimer) {
        [self send];
    }
}

- (void)reachabilityChanged {
    if ([BAReachabilityHelper isInternetReachable] && _retryTimer) {
        // Force a retry
        [self send];
    }
}

- (void)trackingWebserviceDidSucceedForEvents:(NSArray *)array {
    [_sender trackingWebserviceDidFinish:YES forEvents:array];

    _currentRetryDelay = _initialRetryDelay;
    [self newEventsAvailable];
}

- (void)trackingWebserviceDidFail:(NSError *)error forEvents:(NSArray *)array {
    [_sender trackingWebserviceDidFinish:NO forEvents:array];

    [self incrementDelay];
    [self scheduleTimer];
}

#pragma mark -
#pragma mark Private methods

- (void)incrementDelay {
    // Increment the delay exponentially
    // Don't increment exponentially if this is the first retry, but increment it to know we waited once
    if (_currentRetryDelay == _initialRetryDelay) {
        _currentRetryDelay++;
        return;
    }

    _currentRetryDelay = MIN(_maxRetryDelay, _currentRetryDelay * 2);
}

- (void)scheduleTimer {
    [BAThreading performBlockOnMainThread:^{
      if (self->_retryTimer) {
          [self->_retryTimer invalidate];
      }

      self->_retryTimer = [NSTimer scheduledTimerWithTimeInterval:self->_currentRetryDelay
                                                           target:self
                                                         selector:@selector(send)
                                                         userInfo:nil
                                                          repeats:NO];
    }];
}

- (void)stopTimer {
    [BAThreading performBlockOnMainThread:^{
      if (self->_retryTimer) {
          [self->_retryTimer invalidate];
          self->_retryTimer = nil;
      }
    }];
}

- (void)send {
    [self stopTimer];

    if (![_sender send]) {
        // There was nothing to send, reset the retry timer since trackingWebserviceDidFinish:forEvents: will never be
        // called
        _currentRetryDelay = _initialRetryDelay;
    }
}

@end
