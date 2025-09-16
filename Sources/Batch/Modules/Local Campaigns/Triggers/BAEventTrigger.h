//
//  BAEventTrigger.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BALocalCampaignTriggerProtocol.h>
#import <Batch/BatchEventAttributes.h>

#import <Foundation/Foundation.h>

@interface BAEventTrigger : NSObject <BALocalCampaignTriggerProtocol>

@property (nonnull, copy) NSString *name;

@property (nullable, copy) NSString *label;

@property (nullable, copy) NSDictionary *attributes;

- (nonnull instancetype)initWithName:(nonnull NSString *)name
                               label:(nullable NSString *)label
                          attributes:(nullable NSDictionary *)attributes;

+ (nonnull instancetype)triggerWithName:(nonnull NSString *)name
                                  label:(nullable NSString *)label
                             attributes:(nullable NSDictionary *)attributes;

- (BOOL)isSatisfiedForName:(nonnull NSString *)name label:(nullable NSString *)label;

- (BOOL)isSatisfiedForAttributes:(nullable NSDictionary *)attributes;

@end
