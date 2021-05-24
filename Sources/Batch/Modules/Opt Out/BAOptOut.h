#import <Foundation/Foundation.h>

#import <Batch/BatchCore.h>

#define OptOutUserDefaultsSuite @"com.batch.sdk.optout"
#define OptOutDefaultKey @"opted_out"
#define ShouldFireOptinEventDefaultKey @"should_fire_optin_event"

extern NSString * _Nonnull const kBATOptOutChangedNotification;
extern NSString * _Nonnull const kBATOptOutValueKey;
extern NSString * _Nonnull const kBATOptOutWipeDataKey;

@class BAOptOutEventTracker;

@interface BAOptOut : NSObject

+ (nonnull BAOptOut *)instance;

- (void)setOptedOut:(BOOL)newVal wipeData:(BOOL)wipeData completionHandler:(BatchOptOutNetworkErrorPolicy(^ _Nonnull)(BOOL success))handler;

- (BOOL)isOptedOut;

- (void)fireOptInEventIfNeeded;

// Testing methods

- (void)refresh;

- (void)initEventTrackerIfNeeded;

- (void)setEventTracker:(nullable BAOptOutEventTracker*)eventTracker;

- (void)applyOptOut:(BOOL)shouldOptOut wipeData:(BOOL)wipeData;

@end
