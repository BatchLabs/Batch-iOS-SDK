//
//  Defined.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BANullHelper.h>

#define ERROR_DOMAIN @"com.batch.ios"
#define PROFILE_ERROR_DOMAIN @"com.batch.ios.profile"
#define NETWORKING_ERROR_DOMAIN @"com.batch.ios.networking"
#define MESSAGING_ERROR_DOMAIN @"com.batch.ios.messaging"
#define WEBVIEW_ERROR_DOMAIN @"com.batch.ios.webview"
#define BRIDGE_ERROR_DOMAIN @"com.batch.ios.webview.bridge"

#define INIT_AND_BLANK_ERROR_IF_NEEDED(error) \
    if (error == NULL) {                      \
        __autoreleasing NSError *fakeOutErr;  \
        error = &fakeOutErr;                  \
    }                                         \
    *error = nil;

#define BAPrivateKeyStorage @"Pm1oZKMo"
#define BAPrivateKeyWebservice @"wgHD"
#define BAPrivateKeyWebserviceV2 @"jgfx"
#define BABastionBundleIdentifier @"com.bastionsdk"
#define BABundleIdentifier @"com.batch.ios"
#define BAProductIdentifier @"IOS-com.batch.ios"

// Read receipt
#define kParametersReadReceiptEventName @"_PUSH_RECEIVED"

// Application parameters.
#define kParametersProjectKey @"app.project.key"
#define kParametersLocalInstallIdentifierKey @"app.install.id"
#define kParametersLocalInstallDateIdentifierKey @"app.install.timestamp"
#define kParametersLocalIcloudIdentifierKey @"app.icloud.id"
#define kParametersLocalIcloudDateIdentifierKey @"app.icloud.timestamp"

#define kParametersPoolWebserviceMaxKey @"app.executor.maxpool"
#define kParametersSystemCurrentAppVersionKey @"app.version.current"
#define kParametersSystemPreviousAppVersionKey @"app.version.previous"

#define kParametersSystemParameterPrefix @"app.system.param."
#define kParametersDataCollectionConfigKey @"app.data.collection.config."

#define kParametersCustomUserIDKey @"app.id.custom"
#define kParametersAppLanguageKey @"app.language"
#define kParametersAppRegionKey @"app.region"

#define kParametersAppProfileVersionKey @"app.profile.version"

#define kParametersDateFormat @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"

// Push keys
#define kParametersPushTokenKey @"push.token"
#define kParametersPushTokenIsProductionKey @"push.token.isproduction"

// Latest notification authorization status sent to the server
#define kParametersNotificationAuthSentStatusKey @"notification.auth.sentstatus"

// Tracker parameters.

#define kParametersTrackerDBLimitKey @"tracker.db.limit"
#define kParametersTrackerDBLimitValue @10000

#define kParametersTrackerInitialDelayKey @"tracker.delay.initial"
#define kParametersTrackerInitialDelayValue @10

#define kParametersTrackerMaxDelayKey @"tracker.delay.max"
#define kParametersTrackerMaxDelayValue @120

#define kParametersTrackerWebserviceEventLimitKey @"tracker.ws.limit"
#define kParametersTrackerWebserviceEventLimitValue @20

#define kParametersTrackerDBVersion @"tracker.db.version"

// Inbox Parameters.

#define kParametersInboxDBVersion @"inbox.db.version"

// User profile
#define kParametersUserProfileDataVersionKey @"user_profile.data.version"
#define kParametersUserProfileTransactionIDKey @"user_profile.trid"
#define kParametersUserProfileDBVersion @"user_profile.db.version"
#define kParametersUserStartCheckInitialDelay @1000

#define kParametersInAppTrackerDBVersion @"messaging.inapp.db.version"

#define kParametersLocalCampaignsInitialWSDelayKey @"lc.wsdelay.initial"
#define kParametersLocalCampaignsInitialWSDelayValue @5

#define kParametersServerTimestamp @"ws.server.timestamp"
#define kParametersCipherV2LastFailure @"ws.cipherv2.lastfailure"
#define kCipherFallbackResetTime 172800
#define kCipherFallbackHTTPErrorCode 487

// Webservice keys.

// Maximum number of concurrent network requests for BAWebserviceClient
#define kWebserviceClientExecutorMaxConcurrency 2

#define kQueryWebserviceTypeStart @"START"
#define kQueryWebserviceTypePush @"PUSH"
#define kQueryWebserviceTypeTracking @"TRACKING"
#define kQueryWebserviceTypeAttributes @"ATTRIBUTES"
#define kQueryWebserviceTypeAttributesCheck @"ATTRIBUTES_CHECK"
#define kQueryWebserviceTypeLocalCampaigns @"LOCAL_CAMPAIGNS"

#define kWebserviceKeyMainHeader @"header"
#define kWebserviceKeyMainStatus @"status"
#define kWebserviceKeyMainBody @"body"
#define kWebserviceKeyQueryIdentifier @"id"
#define kWebserviceKeyTimestamp @"ts"
#define kWebserviceKeyQueryType @"type"

// Various keys used in queries
#define kWebserviceKeyQuerySilentStart @"silent"

#define kWebserviceKeyQueryEvents @"evts"

#define kWebserviceKeyQueryToken @"tok"
#define kWebserviceKeyQueryProduction @"prod"
#define kWebserviceKeyQueryNotifType @"nty"

#define kWebserviceKeyPushBatchData @"com.batch"
#define kWebserviceKeyPushDeeplink @"l"
#define kWebserviceKeyDeeplinkOpenInApp @"li"
#define kWebserviceKeyPushId @"i"
#define kWebserviceKeyPushOpenEventData @"od"
#define kWebserviceKeyPushType @"t"
#define kWebserviceKeyPushExperiment @"ex"
#define kWebserviceKeyPushVariant @"va"

// URL shortnames
#define kParametersStartWebserviceShortname @"st"
#define kParametersPushWebserviceShortname @"t"
#define kParametersTrackingWebserviceShortname @"tr"
#define kParametersAttributesSendWebserviceShortname @"ats"
#define kParametersAttributesCheckWebserviceShortname @"atc"
#define kParametersInboxWebserviceShortname @"inbox"
#define kParametersLocalCampaignsWebserviceShortname @"local"
#define kParametersLocalCampaignsJITWebserviceShortname @"lc_jit"

// DNS Fallback
#define kParametersDomainKey @"batch.domain.current"
#define kParametersDomainErrorCountKey @"batch.domain.current.error.count"
#define kParametersDomainErrorUpdateDate @"batch.domain.current.error.last_update.date"
#define kParametersDomainErrorLimitCount 3
#define kParametersDomainErrorMinDelaySecond 5
#define kParametersDomainOriginal @"batch.com"
#define kParametersDomainLastUpdateDate @"batch.domain.current.last_update.date"
#define kParametersDomainLastCheckMinDelaySecond 172800
#define kParametersDomainLastCheckDate @"batch.domain.original.last_check.date"
#define kParametersDNSFallbackFeatureFlag 0

// Mobile landing & In-app MEP & CEP
#define BATCH_MESSAGE_MEP_CTA_INDEX_KEY @"mepCtaIndex:"
