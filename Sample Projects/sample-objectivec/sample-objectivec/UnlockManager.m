//
//  UnlockManager.m
//  sample-objectivec
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

#import "UnlockManager.h"

#define NO_ADS_KEY @"no_ads"
#define NO_ADS_DEFAULT_VALUE false
#define NO_ADS_REFERENCE @"NO_ADS"

#define LIVES_KEY @"lives"
#define LIVES_DEFAULT_VALUE 10l
#define LIVES_REFERENCE @"LIVES"

#define PRO_TRIAL_KEY @"pro_trial"
#define PRO_TRIAL_DEFAULT_VALUE 0l
#define PRO_TRIAL_REFERENCE @"PRO_TRIAL"

@implementation UnlockManager

- (void)showRedeemAlertForOffer:(id<BatchOffer>)offer withViewController:(UIViewController *)viewController {
    NSString *rewardMessage = [[offer offerAdditionalParameters] objectForKey:@"reward_message"];
    if (rewardMessage) {
        NSLog(@"Displaying 'reward_message' additional parameter");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:rewardMessage preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Thanks!" style:UIAlertActionStyleDefault handler:nil]];
        [viewController presentViewController:alert animated:true completion:nil];
    } else {
        NSLog(@"Didn't find an additional parameter named 'reward_message' to display a reward confirmation message");
    }
}

- (void)unlockItemsFromOffer:(id<BatchOffer>)offer {
    if ([offer hasFeatures]) {
        [self unlockFeatures:[offer features]];
    }
    
    for (id<BatchResource> resource in [offer resources]) {
        if ([LIVES_REFERENCE isEqualToString:[resource reference]]) {
            NSLog(@"Unlocking %lu %@", (unsigned long)[resource quantity], LIVES_REFERENCE);
            [self writeUnsignedLong:([self lives] + [resource quantity]) forKey:LIVES_KEY];
        }
    }
}

- (void)unlockFeatures:(NSArray *)features {
    for (id<BatchFeature> feature in features) {
        if ([NO_ADS_REFERENCE isEqualToString:[feature reference]]) {
            NSLog(@"Unlocking %@", NO_ADS_REFERENCE);
            [self writeBool:true forKey:NO_ADS_KEY];
        } else if ([PRO_TRIAL_REFERENCE isEqualToString:[feature reference]]) {
            if ([feature isLifetime]) {
                NSLog(@"Unlocking %@ forever", PRO_TRIAL_REFERENCE);
                [self writeLongLong:-1 forKey:PRO_TRIAL_KEY];
            } else {
                NSLog(@"Unlocking %@ for %lu seconds", PRO_TRIAL_REFERENCE, (unsigned long)[feature ttl]);
                // Store the timestamp of expiration
                [self writeLongLong:([[NSDate date] timeIntervalSince1970] + [feature ttl]) forKey:PRO_TRIAL_KEY];
            }
        }
    }
}

- (BOOL)hasNoAds {
    return [self readBoolForKey:NO_ADS_KEY defaultValue:NO_ADS_DEFAULT_VALUE];
}

- (unsigned long)lives {
    return [self readUnsignedLong:LIVES_KEY defaultValue:LIVES_DEFAULT_VALUE];
}

- (void)setLives:(unsigned long)lives {
    [self writeUnsignedLong:lives forKey:LIVES_KEY];
}

- (BOOL)hasProTrial {
    // Since -1 means unlimited
    return [self timeLeftForProTrial] != 0;
}

- (long long)timeLeftForProTrial {
    long long expirationDate = [self readLongLong:PRO_TRIAL_KEY defaultValue:PRO_TRIAL_DEFAULT_VALUE];
    if (expirationDate == -1) {
        return -1;
    }
    return MAX(expirationDate - [[NSDate date] timeIntervalSince1970], 0);
}

#pragma Private storage helper methods

- (BOOL)readBoolForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    id objectValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if ([objectValue isKindOfClass:[NSNumber class]]) {
        return [objectValue boolValue];
    }
    return defaultValue;
}

- (unsigned long)readUnsignedLong:(NSString *)key defaultValue:(unsigned long)defaultValue {
    id objectValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if ([objectValue isKindOfClass:[NSNumber class]]) {
        return [objectValue unsignedLongValue];
    }
    return defaultValue;
}

- (long long)readLongLong:(NSString *)key defaultValue:(long long)defaultValue {
    id objectValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if ([objectValue isKindOfClass:[NSNumber class]]) {
        return [objectValue longLongValue];
    }
    return defaultValue;
}

- (void)writeBool:(BOOL)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)writeLongLong:(long long)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)writeUnsignedLong:(unsigned long)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
