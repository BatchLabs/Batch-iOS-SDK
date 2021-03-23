//
//  BAUserProfile.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAUserProfile.h>

#import <Batch/BAParameter.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BATrackerCenter.h>

@implementation BAUserProfile

#pragma mark -
#pragma mark Instance methods

static const int currentVersion = 1;

+ (void)initialize
{
    if (self == [BAUserProfile class])
    {
        [self setVersion:currentVersion];
    }
}

+ (BAUserProfile *)defaultUserProfile
{
    static BAUserProfile *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BAUserProfile alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if ([BANullHelper isNull:self])
    {
        return self;
    }
    
    return self;
}

// Key-Value dictionary representation of a user profile.
- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *keyValues = [[NSMutableDictionary alloc] init];
    [keyValues setValue:[self language] forKey:@"ula"];
    [keyValues setValue:[self region] forKey:@"ure"];
    [keyValues setValue:[self version] forKey:@"upv"];
    
    return [NSDictionary dictionaryWithDictionary:keyValues];
}

// Method that saves a parameter and bumps data version if needed
- (NSError*)updateValue:(NSString*)value forKey:(NSString*)key
{
    NSError *error = nil;
    if ([BANullHelper isStringEmpty:value])
    {
        // Reset the custom identifier, language or region
        error = [BAParameter removeObjectForKey:key];
    }
    else
    {
        // Change the value.
        error = [BAParameter setValue:value forKey:key saved:YES];
    }
    
    return error;
}

- (void)incrementVersion
{
    @synchronized(self)
    {
        NSNumber *version = [self version];
        // Sanity
        if (![version isKindOfClass:[NSNumber class]])
        {
            [BAParameter setValue:@(1) forKey:kParametersAppProfileVersionKey saved:YES];
        }
        else
        {
            [BAParameter setValue:@([version longLongValue] + 1) forKey:kParametersAppProfileVersionKey saved:YES];
        }
        
        NSMutableDictionary *eventParameters = [[self dictionaryRepresentation] mutableCopy];
        [eventParameters setValue:[self customIdentifier] forKey:@"cus"];
        
        [BATrackerCenter trackPrivateEvent:@"_PROFILE_CHANGED" parameters:eventParameters];
    }
}

#pragma mark -
#pragma mark Properties override methods

- (NSNumber*)version
{
    @synchronized(self)
    {
        return [BAParameter objectForKey:kParametersAppProfileVersionKey fallback:@(1)];
    }
}

/*** Custom Identifier ***/

- (NSString *)customIdentifier
{
    return [BAParameter objectForKey:kParametersCustomUserIDKey fallback:nil];
}

- (void)setCustomIdentifier:(NSString *)customIdentifier
{
    NSError *error = [self updateValue:customIdentifier forKey:kParametersCustomUserIDKey];
    
    if (error != nil)
    {
        [BALogger errorForDomain:@"UserProfile" message:@"Error changing custom identifier: %@", [error localizedDescription]];
    }
}

/*** Language ***/

- (NSString *)language
{
    return [BAParameter objectForKey:kParametersAppLanguageKey fallback:nil];
}

- (void)setLanguage:(NSString *)language
{
    NSError *error = [self updateValue:language forKey:kParametersAppLanguageKey];
    
    if (error != nil)
    {
        [BALogger errorForDomain:@"UserProfile" message:@"Error changing the language: %@", [error localizedDescription]];
    }
}

/*** Region ***/

- (NSString *)region
{
    return [BAParameter objectForKey:kParametersAppRegionKey fallback:nil];
}

- (void)setRegion:(NSString *)region
{
    NSError *error = [self updateValue:region forKey:kParametersAppRegionKey];
    
    if (error != nil)
    {
        [BALogger errorForDomain:@"UserProfile" message:@"Error changing the region: %@", [error localizedDescription]];
    }
}


#pragma mark -
#pragma mark NSCoding archive methods

- (void)encodeWithCoder:(NSCoder *)encoder
{
    // Encode properties.
    [encoder encodeObject:self.customIdentifier forKey:@"customIdentifier"];
    [encoder encodeObject:self.language forKey:@"language"];
    [encoder encodeObject:self.region forKey:@"region"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if((self = [super init]))
    {
        long version = [decoder versionForClassName:NSStringFromClass([BAUserProfile class])];
        
        if (version < currentVersion)
        {
            // Manage old versions.
        }
        
        // Decode properties.
        self.customIdentifier = [decoder decodeObjectForKey:@"customIdentifier"];
        self.language = [decoder decodeObjectForKey:@"language"];
        self.region = [decoder decodeObjectForKey:@"region"];
    }
    
    return self;
}

@end
