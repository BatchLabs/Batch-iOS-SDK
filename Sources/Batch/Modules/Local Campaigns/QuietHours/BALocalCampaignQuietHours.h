//
//  BALocalCampaignsQuietHours.h
//  Batch
//
//  Copyright © 2025 Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents the "quiet hours" settings for local campaigns, during which notifications should not be displayed.
 */
@interface BALocalCampaignQuietHours : NSObject

/// The starting hour of the quiet period (0-23).
@property (nonatomic) NSInteger startHour;

/// The starting minute of the quiet period (0-59).
@property (nonatomic) NSInteger startMin;

/// The ending hour of the quiet period (0-23).
@property (nonatomic) NSInteger endHour;

/// The ending minute of the quiet period (0-59).
@property (nonatomic) NSInteger endMin;

/// An array of BALocalCampaignDayOfWeek objects representing the days of the week for quiet hours.
@property (nonatomic, nullable, strong) NSArray<NSNumber *> *quietDaysOfWeek;

/**
 Initializes a BALocalCampaignsQuietHours object from a dictionary.

 @param dictionary The dictionary containing the quiet hours data, typically parsed from JSON.
 @return An initialized BALocalCampaignsQuietHours object, or nil if the dictionary is invalid.
 */
- (nullable instancetype)initWithDictionary:(nonnull NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
