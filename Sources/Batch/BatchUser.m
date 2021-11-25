//
//  BatchUser.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BatchUser.h>
#import <Batch/BAUserDataEditor.h>
#import <Batch/BAUserDataManager.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BatchEventDataPrivate.h>
#import <Batch/BatchUserAttribute.h>
#import <Batch/BAUserSQLiteDatasource.h>
#import <Batch/BatchUserAttributePrivate.h>
#import <Batch/BAUserProfile.h>
#import <Batch/BAInjectable.h>

#define EVENT_NAME_REGEXP @"^[a-zA-Z0-9_]{1,30}$"

NSString *const BatchEventTrackerFinishedNotification = @"BatchEventTrackerFinishedNotification";

NSString *const BatchEventTrackerFinishedWithSuccessKey = @"BatchEventTrackerFinishedWithSuccessKey";

NSErrorDomain const BatchUserDataEditorErrorDomain = @"com.batch.ios.userdataeditor";

@implementation BatchUser

+ (nullable NSString*)installationID
{
    return [[BAPropertiesCenter valueForShortName:@"di"] uppercaseString];
}

+ (nonnull BatchUserDataEditor*)editor
{
    return [BatchUserDataEditor new];
}

+ (nonnull NSString *)language
{
    NSString *savedLanguage = [[BAUserProfile defaultUserProfile] language];
    return savedLanguage;
}

+ (nonnull NSString *)region
{
    NSString *savedRegion = [[BAUserProfile defaultUserProfile] region];
    return savedRegion;
}

+ (nullable NSString *)identifier
{
    return [[BAUserProfile defaultUserProfile] customIdentifier];
}

+ (void)fetchAttributes:(void (^)(NSDictionary<NSString*, BatchUserAttribute*>* _Nullable))completionHandler
{
    dispatch_async([BAUserDataManager sharedQueue], ^{
        id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
        NSDictionary<NSString*, BAUserAttribute*> *privateAttributes = [datasource attributes];
        NSMutableDictionary<NSString*, BatchUserAttribute*> *publicAttributes = [NSMutableDictionary new];
        for (NSString* key in privateAttributes) {
            BAUserAttribute *privateAttribute = privateAttributes[key];
            
            BatchUserAttributeType publicType;
            switch (privateAttribute.type) {
                case BAUserAttributeTypeBool:
                    publicType = BatchUserAttributeTypeBool;
                    break;
                case BAUserAttributeTypeDate:
                    publicType = BatchUserAttributeTypeDate;
                    break;
                case BAUserAttributeTypeString:
                    publicType = BatchUserAttributeTypeString;
                    break;
                case BAUserAttributeTypeLongLong:
                    publicType = BatchUserAttributeTypeLongLong;
                    break;
                case BAUserAttributeTypeDouble:
                    publicType = BatchUserAttributeTypeDouble;
                    break;
                case BAUserAttributeTypeURL:
                    publicType = BatchUserAttributeTypeURL;
                    break;
                default:
                    continue; // We skip attributes whose type is not dealt with above.
                    break;
            }
            
            BatchUserAttribute *publicAttribute = [[BatchUserAttribute alloc] initWithValue:privateAttribute.value
                                                                                       type:publicType];
            
            // Clean the key so that it is equal to the one used when setting the attribute.
            NSString *userKey = [key stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString: @""];
            publicAttributes[userKey] = publicAttribute;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler([publicAttributes copy]);
        });
    });
}

+ (void)fetchTagCollections:(void (^)(NSDictionary<NSString *,NSSet<NSString *> *> * _Nullable))completionHandler
{
    dispatch_async([BAUserDataManager sharedQueue], ^{
        id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
        NSDictionary<NSString*, NSSet<NSString*>*>* tagCollections = [datasource tagCollections];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(tagCollections);
        });
    });
}

+ (void)trackEvent:(nonnull NSString*)event
{
    [BatchUser trackEvent:event withLabel:nil associatedData:nil];
}

+ (void)trackEvent:(nonnull NSString*)event withLabel:(nullable NSString*)label
{
    [BatchUser trackEvent:event withLabel:label associatedData:nil];
}

+ (void)trackEvent:(nonnull NSString*)event withLabel:(nullable NSString*)label data:(nullable NSDictionary*)legacyData
{
    BatchEventData *data = nil;
    if (legacyData != nil)
    {
        data = [BatchEventData new];
        [data _copyLegacyData:legacyData];
    }
    
    [BatchUser trackEvent:event withLabel:label associatedData:data];
}
    
+ (void)trackEvent:(nonnull NSString*)event withLabel:(nullable NSString*)label associatedData:(nullable BatchEventData*)data
{
    static id eventNameValidationRegexp = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        
        NSError *error = nil;
        
        eventNameValidationRegexp = [NSRegularExpression regularExpressionWithPattern:EVENT_NAME_REGEXP
                                                                              options:0
                                                                                error:&error];
        if (error)
        {
            // Something went really wrong, so we'll just throw internal errors
            [BALogger errorForDomain:@"BatchUser - Events" message:@"Error while creating event name regexp."];
            eventNameValidationRegexp = nil;
        }
    });
    
    if (!eventNameValidationRegexp)
    {
        [BALogger publicForDomain:@"BatchUser - Events" message:@"Internal error. Ignoring attribute '%@'.", event];
        return;
    }
    
    BOOL eventValidated = NO;
    
    if ([event isKindOfClass:[NSString class]])
    {
        NSRange matchingRange = [eventNameValidationRegexp rangeOfFirstMatchInString:event
                                                                             options:0
                                                                               range:NSMakeRange(0, event.length)];
        if (matchingRange.location != NSNotFound)
        {
            eventValidated = YES;
        }
    }
    
    
    if (!eventValidated)
    {
        [BALogger publicForDomain:@"BatchUser - Events" message:@"Invalid event name ('%@'). Not tracking.", event];
        return;
    }
    
    if (![label isKindOfClass:[NSString class]])
    {
        label = nil;
    }
    
    if (![data isKindOfClass:[BatchEventData class]])
    {
        data = nil;
    }
    
    [BATrackerCenter trackPublicEvent:event.uppercaseString label:label data:data];
}

+ (void)trackTransactionWithAmount:(double)amount
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [BatchUser trackTransactionWithAmount:amount data:nil];
#pragma clang diagnostic pop
}

+ (void)trackTransactionWithAmount:(double)amount data:(nullable NSDictionary*)legacyData
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    [params setObject:[NSNumber numberWithDouble:amount] forKey:BA_PUBLIC_EVENT_KEY_AMOUNT];
    
    BatchEventData *data = nil;
    if (legacyData != nil)
    {
        data = [BatchEventData new];
        [data _copyLegacyData:legacyData];
        [params addEntriesFromDictionary:[data _internalDictionaryRepresentation]];
    }
    
    [BATrackerCenter trackPrivateEvent:@"T" parameters:params];
}

+ (void)trackLocation:(nonnull CLLocation*)location
{
    [BATrackerCenter trackLocation:location];
}

+ (void)printDebugInformation
{
    [BAUserDataManager printDebugInformation];
}

@end

@implementation BatchUserDataEditor
{
    BAUserDataEditor *_backingImpl;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _backingImpl = [BAInjection injectClass:BAUserDataEditor.class];
    }
    return self;
}

- (void)setLanguage:(nullable NSString*)language
{
    [_backingImpl setLanguage:language];
}

- (void)setRegion:(nullable NSString*)region
{
    [_backingImpl setRegion:region];
}

- (void)setIdentifier:(nullable NSString*)identifier
{
    [_backingImpl setIdentifier:identifier];
}

- (void)setAttribute:(nullable NSObject*)attribute forKey:(nonnull NSString*)key
{
    [_backingImpl setAttribute:attribute forKey:key];
}

- (BOOL)setBooleanAttribute:(BOOL)attribute forKey:(NSString *)key error:(NSError **)error {
    return [_backingImpl setBooleanAttribute:attribute forKey:key error:error];
}

- (BOOL)setDateAttribute:(NSDate *)attribute forKey:(NSString *)key error:(NSError **)error {
    return [_backingImpl setDateAttribute:attribute forKey:key error:error];
}

- (BOOL)setStringAttribute:(NSString *)attribute forKey:(NSString *)key error:(NSError **)error {
    return [_backingImpl setStringAttribute:attribute forKey:key error:error];
}

- (BOOL)setNumberAttribute:(NSNumber *)attribute forKey:(NSString *)key error:(NSError **)error {
    return [_backingImpl setNumberAttribute:attribute forKey:key error:error];
}

- (BOOL)setIntegerAttribute:(NSInteger)attribute forKey:(NSString *)key error:(NSError **)error {
    return [_backingImpl setIntegerAttribute:attribute forKey:key error:error];
}

- (BOOL)setLongLongAttribute:(long long int)attribute forKey:(NSString *)key error:(NSError **)error {
    return [_backingImpl setLongLongAttribute:attribute forKey:key error:error];
}

- (BOOL)setFloatAttribute:(float)attribute forKey:(NSString *)key error:(NSError **)error {
    return [_backingImpl setFloatAttribute:attribute forKey:key error:error];
}

- (BOOL)setDoubleAttribute:(double)attribute forKey:(NSString *)key error:(NSError **)error {
    return [_backingImpl setDoubleAttribute:attribute forKey:key error:error];
}

- (BOOL)setURLAttribute:(nonnull NSURL *)attribute forKey:(NSString *)key error:(NSError **)error {
    return [_backingImpl setURLAttribute:attribute forKey:key error:error];
}

- (void)removeAttributeForKey:(nonnull NSString*)key
{
    [_backingImpl removeAttributeForKey:key];
}

- (void)clearAttributes
{
    [_backingImpl clearAttributes];
}

- (void)addTag:(nonnull NSString*)tag inCollection:(nonnull NSString*)collection
{
    [_backingImpl addTag:tag inCollection:collection];
}

- (void)removeTag:(nonnull NSString*)tag fromCollection:(nonnull NSString*)collection
{
    [_backingImpl removeTag:tag fromCollection:collection];
}

- (void)clearTags
{
    [_backingImpl clearTags];
}

- (void)clearTagCollection:(nonnull NSString*)collection
{
    [_backingImpl clearTagCollection:collection];
}

- (void)save
{
    [_backingImpl save];
}

@end
