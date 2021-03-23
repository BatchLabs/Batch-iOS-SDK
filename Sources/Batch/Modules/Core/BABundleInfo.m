//
//  BABundleInfo.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BABundleInfo.h>

#if TARGET_OS_MACCATALYST
#define PROVISION_ENVIRONMENT_KEY @"com.apple.developer.aps-environment"
#else
#define PROVISION_ENVIRONMENT_KEY @"aps-environment"
#endif

@interface BABundleInfo () {
    NSNumber *_usesAPNSandbox;
}

@end

@implementation BABundleInfo

+ (nonnull instancetype)shared
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

+ (BOOL)isSharedGroupConfigured
{
    return [self sharedGroupDirectory] != nil;
}

+ (nullable NSString *)sharedGroupId
{
    id groupIdOverride = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"BATCH_APP_GROUP_ID"];
    if (![BANullHelper isStringEmpty:groupIdOverride]) {
        return groupIdOverride;
    }
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([BANullHelper isStringEmpty:bundleIdentifier]) {
        return nil;
    }
    
    return [[@"group." stringByAppendingString:bundleIdentifier] stringByAppendingString:@".batch"];
}

+ (nullable NSURL *)sharedGroupDirectory
{
    return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[self sharedGroupId]];
}

+ (nullable NSUserDefaults *)sharedDefaults
{
    NSString *groupId = [self sharedGroupId];
    if (groupId != nil) {
        return [[NSUserDefaults alloc] initWithSuiteName:groupId];
    }
    return nil;
}

- (BOOL)usesAPNSandbox
{
    if (_usesAPNSandbox == nil) {
    #if TARGET_OS_SIMULATOR
        [BALogger debugForDomain:@"BAMobileProvision" message:@"Running on a simulator, simulating a dev env"];
        _usesAPNSandbox = @true;
    #else
        _usesAPNSandbox = @([self readAPNEnvironmentFromProvision]);
    #endif
    }

    return _usesAPNSandbox.boolValue;
}

- (BOOL)readAPNEnvironmentFromProvision
{
    NSDictionary *provision = [self mobileProvision];
    
    NSDictionary *entitlements = [provision objectForKey:@"Entitlements"];
    if ([entitlements isKindOfClass:[NSDictionary class]] &&
        [@"development" isEqualToString:[entitlements objectForKey:PROVISION_ENVIRONMENT_KEY]])
    {
        return true;
    }
    
    return false;
}

- (NSDictionary *)mobileProvision
{
    NSDictionary* mobileProvision = nil;
#if TARGET_OS_MACCATALYST
    NSString *provisioningPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"Contents/embedded.provisionprofile"];
#else
    NSString *provisioningPath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
#endif
    if (!provisioningPath)
    {
        return nil;
    }
    // NSISOLatin1 keeps the binary wrapper from being parsed as unicode and dropped as invalid
    NSString *binaryString = [NSString stringWithContentsOfFile:provisioningPath encoding:NSISOLatin1StringEncoding error:NULL];
    if (!binaryString)
    {
        return nil;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:binaryString];
    BOOL ok = [scanner scanUpToString:@"<plist" intoString:nil];
    if (!ok)
    {
        [BALogger debugForDomain:@"BAMobileProvision" message:@"Unable to find the beginning of the plist"];
        return nil;
    }
    
    NSString *plistString;
    ok = [scanner scanUpToString:@"</plist>" intoString:&plistString];
    if (!ok)
    {
        [BALogger debugForDomain:@"BAMobileProvision" message:@"Unable to find the end of the plist"];
        return nil;
    }
    
    plistString = [NSString stringWithFormat:@"%@</plist>",plistString];
    // juggle latin1 back to utf-8!
    NSData *plistdata_latin1 = [plistString dataUsingEncoding:NSISOLatin1StringEncoding];
    //		plistString = [NSString stringWithUTF8String:[plistdata_latin1 bytes]];
    //		NSData *plistdata2_latin1 = [plistString dataUsingEncoding:NSISOLatin1StringEncoding];
    NSError *error = nil;
    mobileProvision = [NSPropertyListSerialization propertyListWithData:plistdata_latin1 options:NSPropertyListImmutable format:NULL error:&error];
    if (error)
    {
        [BALogger debugForDomain:@"BAMobileProvision" message:@"Error while parsing extracted plist — %@", error];
        
        if (mobileProvision)
        {
            mobileProvision = nil;
        }
        return nil;
    }
    
    return mobileProvision;
}

+ (BOOL)usesAPNSandbox
{
    return [[BABundleInfo shared] usesAPNSandbox];
}

@end
