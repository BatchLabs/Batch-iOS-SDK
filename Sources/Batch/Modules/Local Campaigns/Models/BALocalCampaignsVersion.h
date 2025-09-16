//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

/** String constant for MEP version in payloads */
#define kParametersLocalCampaignsVersionMEP @"MEP"

/** String constant for CEP version in payloads */
#define kParametersLocalCampaignsVersionCEP @"CEP"

/** Payload key for campaigns version information */
#define kParametersLocalCampaignsVersionPayloadKey @"campaigns_version"

/**
 * Enumeration representing the version of local campaigns.
 * Determines the level of customer user ID support and feature availability.
 */
typedef NS_ENUM(int, BALocalCampaignsVersion) {
    /** MEP (Marketing Engagement Platform) version - basic functionality without customer user ID support */
    BALocalCampaignsVersionMEP = 0,
    /** CEP (Customer Engagement Platform) version - advanced functionality with customer user ID support */
    BALocalCampaignsVersionCEP = 1,
    /** Unknown version - fallback when version cannot be determined */
    BALocalCampaignsVersionUnknown = 2
};
