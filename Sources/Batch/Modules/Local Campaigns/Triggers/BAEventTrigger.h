//
//  BAEventTrigger.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BALocalCampaignTriggerProtocol.h>

@interface BAEventTrigger : NSObject <BALocalCampaignTriggerProtocol>

@property (nonnull, copy) NSString *name;

@property (nullable, copy) NSString *label;

- (nonnull instancetype)initWithName:(nonnull NSString *)name label:(nullable NSString *)label;

+ (nonnull instancetype)triggerWithName:(nonnull NSString *)name label:(nullable NSString *)label;

- (BOOL)isSatisfiedForName:(nonnull NSString *)name label:(nullable NSString *)label;

@end
