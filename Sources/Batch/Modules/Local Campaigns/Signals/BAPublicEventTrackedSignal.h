//
//  BAPublicEventTrackedSignal.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaignSignalProtocol.h>

@class BatchEventAttributes;

@interface BAPublicEventTrackedSignal : NSObject <BALocalCampaignSignalProtocol>

@property (nonnull, copy) NSString *name;

@property (nullable, copy) NSString *label;

@property (nullable, assign) BatchEventAttributes *attributes;

- (nonnull instancetype)initWithName:(nonnull NSString *)name
                               label:(nullable NSString *)label
                          attributes:(nullable BatchEventAttributes *)attributes;

@end
