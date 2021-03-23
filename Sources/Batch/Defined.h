//
//  Defined.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BANullHelper.h>

#include <Batch/Versions.h>

#define ERROR_DOMAIN    @"com.batch.ios"
#define NETWORKING_ERROR_DOMAIN    @"com.batch.ios.networking"
#define MESSAGING_ERROR_DOMAIN    @"com.batch.ios.messaging"
#define WEBVIEW_ERROR_DOMAIN @"com.batch.ios.webview"
#define BRIDGE_ERROR_DOMAIN @"com.batch.ios.webview.bridge"

#define INIT_AND_BLANK_ERROR_IF_NEEDED(error) \
if (error == NULL) {\
    __autoreleasing NSError *fakeOutErr;\
    error = &fakeOutErr;\
}\
*error = nil;

// Enable IDFA related code
// Even though IDFA collection is based on AdSupport being linked to the app,
// some users might want to remove all IDFA references from the code.
// This is a quick hack until we properly move towards IDFA collection into a plugin.
// Note: this does NOT remove AppTrackingTransparency related code
#ifndef BATCH_ENABLE_IDFA
#define BATCH_ENABLE_IDFA 1
#endif

// BAVersion, BALevel and BAMessagingLevel have moved into Version.h and have been renamed
// Their values are not documented there because the Info.plist header parser is pretty dumb and will include comments
// If you need to get the user facing BAVersion, use BACoreCenter.sdkVersion

// We need two intermedary function to make a quoted define from another define
// One expands the macro parameter
// The other adds the quotes
// It would be simpler to quote this in Versions.h but the plist preprocessor is dumb
#define BAStringifyValue(macro) #macro
#define BAGetStringifiedMacro(macro) BAStringifyValue(macro)
#define BASDKVersionNSString @BAGetStringifiedMacro(BASDKVersion)

#define BAPrivateKeyStorage         @"Pm1oZKMo"
#define BAPrivateKeyWebservice      @"wgHD"
#define BAPrivateKeyWebserviceV2    @"jgfx"
#define BABastionBundleIdentifier   @"com.bastionsdk"
#define BABundleIdentifier          @"com.batch.ios"
#define BAProductIdentifier         @"IOS-com.batch.ios"

// Read receipt
#define kParametersReadReceiptEventName             @"_PUSH_RECEIVED"

// Application parameters.

#define kParametersLocalInstallIdentifierKey        @"app.install.id"
#define kParametersLocalInstallDateIdentifierKey    @"app.install.timestamp"
#define kParametersLocalIcloudIdentifierKey         @"app.icloud.id"
#define kParametersLocalIcloudDateIdentifierKey     @"app.icloud.timestamp"
#define kParametersLocalServerInstallIdentifierKey  @"app.server.id"

#define kParametersPoolWebserviceMaxKey             @"app.executor.maxpool"
#define kParametersSystemCurrentAppVersionKey       @"app.version.current"
#define kParametersSystemPreviousAppVersionKey      @"app.version.previous"

#define kParametersIDsPatternKey                    @"app.ids.pattern"
#define kParametersIDsPatternValue                  @"s,da,ada,did,cus,tath,dla,dre,dtz,osv,de,apv,apc,bid,pl,lvl,mlvl,pid,plv,brv,attid_e"

#define kParametersAdvancedIDsPatternKey            @"app.ids.pattern_advanced"
#define kParametersAdvancedIDsPatternValue          @"dty,sop,idfv"

#define kParametersCustomUserIDKey                  @"app.id.custom"
#define kParametersAppLanguageKey                   @"app.language"
#define kParametersAppRegionKey                     @"app.region"
#define kParametersAppProfileVersionKey             @"app.profile.version"

#define kParametersDateFormat                       @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"

// Push keys
#define kParametersPushTokenKey                     @"push.token"
#define kParametersPushTokenIsProductionKey         @"push.token.isproduction"

// Display receipt keys (sharing with extensions)
#define kParametersDisplayReceiptLastApiKey         @"batch_shared_apikey"
#define kParametersDisplayReceiptInstallIdKey       @"batch_shared_installid"
#define kParametersDisplayReceiptCustomIdKey        @"batch_shared_customid"
#define kParametersDisplayReceiptOptOutKey          @"batch_shared_optout"

// Latest notification authorization status sent to the server
#define kParametersNotificationAuthSentStatusKey    @"notification.auth.sentstatus"
#define kParametersAppNotificationSettingsKey       @"notification.auth.appsettings"

// Tracker parameters.

#define kParametersTrackerStateKey                  @"tracker.state"
#define kParametersTrackerStateValue                @2

#define kParametersTrackerDBLimitKey                @"tracker.db.limit"
#define kParametersTrackerDBLimitValue              @10000

#define kParametersTrackerInitialDelayKey           @"tracker.delay.initial"
#define kParametersTrackerInitialDelayValue         @10

#define kParametersTrackerMaxDelayKey               @"tracker.delay.max"
#define kParametersTrackerMaxDelayValue             @120

#define kParametersTrackerWebserviceEventLimitKey   @"tracker.ws.limit"
#define kParametersTrackerWebserviceEventLimitValue @20

#define kParametersTrackerDBVersion                 @"tracker.db.version"

// Inbox Parameters.

#define kParametersInboxDBVersion                   @"inbox.db.version"

// User profile
#define kParametersUserProfileDataVersionKey        @"user_profile.data.version"
#define kParametersUserProfileTransactionIDKey      @"user_profile.trid"
#define kParametersUserProfileDBVersion             @"user_profile.db.version"
#define kParametersUserStartCheckInitialDelay       @1000

#define kParametersInAppTrackerDBVersion            @"messaging.inapp.db.version"

#define kParametersLocalCampaignsInitialWSDelayKey   @"lc.wsdelay.initial"
#define kParametersLocalCampaignsInitialWSDelayValue @5

#define kParametersServerTimestamp                  @"ws.server.timestamp"
#define kParametersCipherV2LastFailure              @"ws.cipherv2.lastfailure"
#define kCipherFallbackResetTime                    172800
#define kCipherFallbackHTTPErrorCode                487

// Webservice keys.

// Maximum number of concurrent network requests for BAWebserviceClient
#define kWebserviceClientExecutorMaxConcurrency     2

#define kQueryWebserviceTypeStart                   @"START"
#define kQueryWebserviceTypePush                    @"PUSH"
#define kQueryWebserviceTypeTracking                @"TRACKING"
#define kQueryWebserviceTypeAttributes              @"ATTRIBUTES"
#define kQueryWebserviceTypeAttributesCheck         @"ATTRIBUTES_CHECK"
#define kQueryWebserviceTypeLocalCampaigns          @"LOCAL_CAMPAIGNS"

#define kWebserviceKeyMainHeader                    @"header"
#define kWebserviceKeyMainStatus                    @"status"
#define kWebserviceKeyMainBody                      @"body"
#define kWebserviceKeyQueryIdentifier               @"id"
#define kWebserviceKeyTimestamp                     @"ts"
#define kWebserviceKeyQueryType                     @"type"

// Various keys used in queries
#define kWebserviceKeyQuerySilentStart              @"silent"

#define kWebserviceKeyQueryEvents                   @"evts"

#define kWebserviceKeyQueryToken                    @"tok"
#define kWebserviceKeyQueryProduction               @"prod"
#define kWebserviceKeyQueryNotifType                @"nty"

#define kWebserviceKeyPushBatchData                 @"com.batch"
#define kWebserviceKeyPushDeeplink                  @"l"
#define kWebserviceKeyDeeplinkOpenInApp             @"li"
#define kWebserviceKeyPushId                        @"i"
#define kWebserviceKeyPushOpenEventData             @"od"
#define kWebserviceKeyPushType                      @"t"
#define kWebserviceKeyPushExperiment                @"ex"
#define kWebserviceKeyPushVariant                   @"va"

#define kParametersWebserviceBase                   @"https://ws.batch.com"
#define kParametersDisplayReceiptWebserviceBase     @"https://drws.batch.com"
#define kParametersWebserviceDomain                 kParametersWebserviceHost @"/i/"

// URL shortnames
#define kParametersStartWebserviceShortname             @"st"
#define kParametersPushWebserviceShortname              @"t"
#define kParametersTrackingWebserviceShortname          @"tr"
#define kParametersAttributesSendWebserviceShortname    @"ats"
#define kParametersAttributesCheckWebserviceShortname   @"atc"
#define kParametersInboxFetchWebserviceShortname        @"inbox"
#define kParametersLocalCampaignsWebserviceShortname    @"local"

// start
#define kParametersStartWebserviceURL               kParametersWebserviceDomain BAVersion @"/" kParametersStartWebserviceShortname

// local campaigns
#define kParametersLocalCampaignsWebserviceURL      kParametersWebserviceDomain BAVersion @"/" kParametersLocalCampaignsWebserviceShortname

