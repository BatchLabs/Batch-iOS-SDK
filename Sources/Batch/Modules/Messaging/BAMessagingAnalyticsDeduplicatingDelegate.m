//
//  BAMessagingAnalyticsDeduplicatingDelegate.m
//  Batch
//

#import <Batch/BAMessagingAnalyticsDeduplicatingDelegate.h>
#import <Batch/BAInjection.h>
#import <Batch/BAMessagingCenter.h>

#define ENSURE_ONCE if ([self ensureMethodCalledOnce:NSStringFromSelector(_cmd)]) { return; }

@implementation BAMessagingAnalyticsDeduplicatingDelegate
{
    id<BAMessagingAnalyticsDelegate> _wrappedDelegate;
    NSMutableSet<NSString*>* _calledMethods;
}

bainjection_injectable_initializer bai_messaging_analytics_init() {
    BAInjectable *injectable = [BAInjectable injectableWithInitializer:^id () {
        return [[BAMessagingAnalyticsDeduplicatingDelegate alloc] initWithWrappedDelegate:[BAInjection injectClass:BAMessagingCenter.class]];
    }];
                             
    [BAInjection registerInjectable:injectable
                        forProtocol:@protocol(BAMessagingAnalyticsDelegate)];
}

- (instancetype)initWithWrappedDelegate:(nonnull id<BAMessagingAnalyticsDelegate>)delegate
{
    self = [super init];
    if (self) {
        _wrappedDelegate = delegate;
        _calledMethods = [[NSMutableSet alloc] initWithCapacity:6];
    }
    return self;
}

- (BOOL)ensureMethodCalledOnce:(NSString*)method
{
    @synchronized (self) {
        if ([_calledMethods containsObject:method]) {
            return true;
        } else {
            [_calledMethods addObject:method];
            return false;
        }
    }
}

- (void)messageShown:(BAMSGMessage* _Nonnull)message
{
    ENSURE_ONCE
    [_wrappedDelegate messageShown:message];
}

- (void)messageClosed:(BAMSGMessage* _Nonnull)message
{
    ENSURE_ONCE
    [_wrappedDelegate messageClosed:message];
}

- (void)message:(BAMSGMessage* _Nonnull)message closedByError:(BATMessagingCloseErrorCause)cause
{
    ENSURE_ONCE
    [_wrappedDelegate message:message closedByError:cause];
}

- (void)messageDismissed:(BAMSGMessage* _Nonnull)message
{
    ENSURE_ONCE
    [_wrappedDelegate messageDismissed:message];
}

- (void)messageButtonClicked:(BAMSGMessage *_Nonnull)message ctaIndex:(NSInteger)ctaIndex action:(BAMSGCTA *)action
{
    ENSURE_ONCE
    [_wrappedDelegate messageButtonClicked:message ctaIndex:ctaIndex action:action];
}

- (void)messageAutomaticallyClosed:(BAMSGMessage* _Nonnull)message
{
    ENSURE_ONCE
    [_wrappedDelegate messageAutomaticallyClosed:message];
}

- (void)messageGlobalTapActionTriggered:(BAMSGMessage *_Nonnull)message action:(BAMSGAction *)action
{
    ENSURE_ONCE
    [_wrappedDelegate messageGlobalTapActionTriggered:message action:action];
}

- (void)messageWebViewClickTracked:(BAMSGMessage *_Nonnull)message
                            action:(BAMSGAction*)action
               analyticsIdentifier:(NSString*)analyticsID
{
    // Not deduplicated, by design
    [_wrappedDelegate messageWebViewClickTracked:message
                                          action:action
                             analyticsIdentifier:analyticsID];
}

@end
