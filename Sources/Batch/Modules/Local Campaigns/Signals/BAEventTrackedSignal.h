//
//  BAEventTrackedSignal.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaignSignalProtocol.h>

@interface BAEventTrackedSignal : NSObject <BALocalCampaignSignalProtocol>

@property (nonnull, copy) NSString *name;

- (nonnull instancetype)initWithName:(nonnull NSString *)name;

@end
