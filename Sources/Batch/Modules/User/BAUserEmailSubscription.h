//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BatchUser.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Enum defining the email kinds for subscription management
typedef NS_ENUM(NSUInteger, BAEmailKind) {
    BAEmailKindMarketing = 0,
};

@interface BAUserEmailSubscription : NSObject

- (instancetype)initWithEmail:(nullable NSString *)email;

- (void)setEmail:(nullable NSString *)email;

- (void)setEmailSubscriptionState:(BatchEmailSubscriptionState)state forKind:(BAEmailKind)kind;

- (void)sendEmailSubscriptionEvent;

@end

NS_ASSUME_NONNULL_END
