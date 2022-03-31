//
//  BAUnlockCenter.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import "BAUnlockCenter.h"

#import "BABatchUnlockDelegateWrapper.h"
#import "BACoreCenter.h"
#import "BAErrorHelper.h"
#import "BAParameter.h"
#import "BAUnlockBlockWrapper.h"
#import "BAWebserviceMulticastDelegate.h"
#import "BAWebservicePool.h"

@interface BAUnlockCenter ()

// Redeem an offer using an URL.
- (BOOL)handleURL:(NSURL *)url;

// Redeem an offer using a code.
- (void)redeemCode:(NSString *)code success:(BatchSuccess)successBlock failure:(BatchFail)failBlock;

// Restore redeemed features.
- (void)restoreFeatures:(BatchRestoreSuccess)success failure:(BatchFail)fail;

@end

@implementation BAUnlockCenter

#pragma mark -
#pragma mark Public methods

// Instance management.
+ (BAUnlockCenter *)instance {
    static BAUnlockCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BAUnlockCenter alloc] init];
    });

    return sharedInstance;
}

+ (void)batchDidStart {
    [[BAUnlockCenter instance] batchDidStart];
}

// Try to find a code from the URL.
+ (BOOL)handleURL:(NSURL *)url {
    return [[BAUnlockCenter instance] handleURL:url];
}

// Give Batch the unlock delegate and activate Batch Unlock system.
+ (void)setupUnlockWithDelegate:(id<BatchUnlockDelegate>)delegate {
    if (delegate == nil) {
        // We can't log this in BABatchUnlockDelegateWrapper since it would throw a false log at first start
        [BALogger publicForDomain:@"Unlock"
                          message:@"%@", [[BAErrorHelper errorInvalidUnlockDelegate] localizedDescription]];
    }

    // Wrapp the input delegate.
    BABatchUnlockDelegateWrapper *wrapperDelegate = [[BABatchUnlockDelegateWrapper alloc] initWithDelgate:delegate];

    [[BAUnlockCenter instance] setUnlockDelegate:wrapperDelegate];
}

// Redeem an offer using a code.
+ (void)redeemCode:(NSString *)code success:(BatchSuccess)successBlock failure:(BatchFail)failBlock {
    BatchSuccess sucessWrapper = [BAUnlockBlockWrapper wrappSuccessBlock:successBlock];
    BatchFail failWrapper = [BAUnlockBlockWrapper wrappFailBlock:failBlock];

    [[BAUnlockCenter instance] redeemCode:code success:sucessWrapper failure:failWrapper];
}

// Restore redeemed features.
+ (void)restoreFeatures:(BatchRestoreSuccess)successBlock failure:(BatchFail)failBlock {
    BatchRestoreSuccess sucessWrapper = [BAUnlockBlockWrapper wrappRestoreSuccessBlock:successBlock];
    BatchFail failWrapper = [BAUnlockBlockWrapper wrappFailBlock:failBlock];

    [[BAUnlockCenter instance] restoreFeatures:sucessWrapper failure:failWrapper];
}

#pragma mark -
#pragma mark Instance methods

- (instancetype)init {
    self = [super init];
    if (self == NULL) {
        return self;
    }

    _unlockDelegate = [[BABatchUnlockDelegateWrapper alloc] initWithDelgate:nil];

    // Create unused features list.
    _unusedOffers = [[BAUnusedOffers alloc] init];

    return self;
}

#pragma mark -
#pragma mark Private methods

- (void)batchDidStart {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkAutomaticUnlocks)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [self checkAutomaticUnlocks];
}

- (void)checkAutomaticUnlocks {
    if (![[self unlockDelegate] hasWrappedDelegate]) {
        return;
    }

    [BALogger debugForDomain:@"UnlockCenter" message:@"%@", @"Checking for unlocks"];
    __block BAStandardWebservice *unlockWebservice = [[BAStandardWebservice alloc] initWithType:@"unlockauto"
                                                                                     identifier:nil
                                                                                       userInfo:@{}];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      // Run start webservice.
      [BAWebservicePool addWebservice:unlockWebservice];
    });
}

// Redeem an offer using an URL.
- (BOOL)handleURL:(NSURL *)url {
    // Check Batch status, must be started.
    if ([[BACoreCenter instance].status isRunning] == NO) {
        [BALogger errorForDomain:ERROR_DOMAIN
                         message:@"%@", [BAErrorHelper errorBatchStoppedOnRedeem].localizedDescription];
        return NO;
    }

    // Check the URL object.
    if ([BANullHelper isNull:url] == YES) {
        [BALogger errorForDomain:ERROR_DOMAIN message:@"%@", [BAErrorHelper errorURLNotFound].localizedDescription];
        return NO;
    }

    // Look for a code.
    NSString *code = [self extractCodeFromURL:url];

    // Check the code.
    if ([BANullHelper isStringEmpty:code] == YES) {
        [BALogger warningForDomain:@"Code from URL" message:@"No valid code found"];
        return NO;
    }
    [BALogger debugForDomain:@"Code from URL" message:@"Code found: %@", code];

    [[self unlockDelegate] URLWithCodeFound:code];

    // Call webservice.
    __block BAStandardWebservice *webservice =
        [[BAStandardWebservice alloc] initWithType:@"code"
                                        identifier:code
                                          userInfo:@{@"code" : code, @"external" : @YES}];

    if ([BANullHelper isNull:webservice]) {
        [BALogger errorForDomain:ERROR_DOMAIN message:@"%@", [BAErrorHelper internalError].localizedDescription];
        [[self unlockDelegate] URLWithCodeFailed:[BAErrorHelper internalError]];

        return NO;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      // Run offer code redeem webservice.
      [BAWebservicePool addWebservice:webservice];
    });

    return YES;
}

// Redeem an offer using a code.
- (void)redeemCode:(NSString *)code success:(BatchSuccess)successBlock failure:(BatchFail)failBlock {
    if (![self.unlockDelegate hasWrappedDelegate]) {
        [BALogger publicForDomain:@"Unlock"
                          message:@"%@", [[BAErrorHelper errorInvalidUnlockDelegate] localizedDescription]];
        failBlock([BAErrorHelper errorInvalidUnlockDelegate]);
        return;
    }

    // Check Batch status, must be started.
    if ([[BACoreCenter instance].status isRunning] == NO) {
        [BALogger publicForDomain:@"Unlock"
                          message:@"%@", [[BAErrorHelper errorBatchStoppedOnRedeem] localizedDescription]];
        failBlock([BAErrorHelper errorBatchStoppedOnRedeem]);
        return;
    }

    // Check block.
    if ([BANullHelper isNull:successBlock] == YES) {
        [BALogger publicForDomain:@"Unlock" message:@"%@", [[BAErrorHelper errorMissingCallback] localizedDescription]];
        failBlock([BAErrorHelper errorMissingCallback]);
        return;
    }

    // Check Code.
    if ([BANullHelper isStringEmpty:code] == YES) {
        [BALogger publicForDomain:@"Unlock" message:@"%@", [[BAErrorHelper errorCodeNotFound] localizedDescription]];
        failBlock([BAErrorHelper errorCodeNotFound]);
        return;
    }

    // Call webservice.
    NSDictionary *info = @{@"code" : code, @"external" : @NO, @"failBlock" : failBlock, @"successBlock" : successBlock};
    __block BAStandardWebservice *webservice = [[BAStandardWebservice alloc] initWithType:@"code"
                                                                               identifier:code
                                                                                 userInfo:info];

    if ([BANullHelper isNull:webservice]) {
        failBlock([BAErrorHelper webserviceError]);
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      // Run offer code redeem webservice.
      [BAWebservicePool addWebservice:webservice];
    });
}

// Restore redeemed features.
- (void)restoreFeatures:(BatchRestoreSuccess)successBlock failure:(BatchFail)failBlock {
    if (![self.unlockDelegate hasWrappedDelegate]) {
        [BALogger publicForDomain:@"Unlock"
                          message:@"%@", [[BAErrorHelper errorInvalidUnlockDelegate] localizedDescription]];
        failBlock([BAErrorHelper errorInvalidUnlockDelegate]);
        return;
    }

    // Check Batch status, must be started.
    if ([[BACoreCenter instance].status isRunning] == NO) {
        [BALogger publicForDomain:@"Unlock"
                          message:@"%@", [[BAErrorHelper errorBatchStoppedOnRedeem] localizedDescription]];
        failBlock([BAErrorHelper errorBatchStoppedOnRedeem]);
        return;
    }

    // Check block.
    if ([BANullHelper isNull:successBlock] == YES) {
        [BALogger publicForDomain:@"Unlock" message:@"%@", [[BAErrorHelper errorMissingCallback] localizedDescription]];
        failBlock([BAErrorHelper errorMissingCallback]);
        return;
    }

    // Call webservice.
    NSDictionary *info = @{@"failBlock" : failBlock, @"successBlock" : successBlock};
    __block BAStandardWebservice *webservice = [[BAStandardWebservice alloc] initWithType:@"restore"
                                                                               identifier:nil
                                                                                 userInfo:info];

    if ([BANullHelper isNull:webservice]) {
        failBlock([BAErrorHelper webserviceError]);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      // Run offer code redeem webservice.
      [BAWebservicePool addWebservice:webservice];
    });
}

// Look for a code in the givent URL.
- (NSString *)extractCodeFromURL:(NSURL *)url {
    NSString *code = nil;

    // Look for a path like: batch…://unlock/code/CODEHERE…
    NSString *schemePattern = [BAParameter objectForKey:kParametersSchemeCodePatternKey
                                               fallback:kParametersSchemeCodePatternValue];

    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:schemePattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if ([BANullHelper isNull:error] == YES) {
        NSArray *values = [regex matchesInString:[url absoluteString]
                                         options:0
                                           range:NSMakeRange(0, [url absoluteString].length)];
        if ([BANullHelper isArrayEmpty:values] == NO) {
            for (NSTextCheckingResult *result in values) {
                NSRange matchRange = [result rangeAtIndex:1];

                // Keep first found.
                NSString *found = [[url absoluteString] substringWithRange:matchRange];
                if ([BANullHelper isStringEmpty:found] == NO) {
                    code = found;
                    break;
                }
            }
        }
    }

    return code;
}

@end
