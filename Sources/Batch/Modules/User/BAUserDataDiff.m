#import <Batch/BAUserDataDiff.h>

typedef NSMutableDictionary<NSString*, NSSet<NSString*>*> BAMutableUserTagCollections;
typedef NSSet<NSString*> TagSet;

@implementation BAUserAttributesDiff

- (instancetype)initWithNewAttributes:(NSDictionary<NSString*, BAUserAttribute*>*)newAttributes previous:(NSDictionary<NSString*, BAUserAttribute*>*)previousAttributes
{
    self = [super init];
    if (self) {
        [self computeWithNewAttributes:newAttributes previous:previousAttributes];
    }
    return self;
}

- (BOOL)hasChanges
{
    return self.added.count != 0 || self.removed.count != 0;
}

- (void)computeWithNewAttributes:(NSDictionary<NSString*, BAUserAttribute*>*)newAttributes previous:(NSDictionary<NSString*, BAUserAttribute*>*)previousAttributes
{
    // Clone the old dictionary, and progressively remove entries that have been found in the new one
    // That way we get a dictionary of missing entries easily
    // If a key is present in both but the value isn't the same, don't remove it from "missingEntries"
    // So that the diff gets a deletion entry for the old value, and an insertion for the new one
    NSMutableDictionary *missingEntries = [previousAttributes mutableCopy];
    
    NSMutableDictionary *newEntries = [NSMutableDictionary new];
    
    for (NSString *key in newAttributes.allKeys) {
        BAUserAttribute *value = newAttributes[key];
        BAUserAttribute *oldValue = previousAttributes[key];
        if (oldValue == nil || ![value isEqual:oldValue]) {
            [newEntries setObject:value forKey:key];
        } else {
            [missingEntries removeObjectForKey:key];
        }
    }
    
    _added = newEntries;
    _removed = missingEntries;
}

@end

@implementation BAUserTagCollectionsDiff

- (instancetype)initWithNewTagCollections:(BAUserTagCollections*)newCollections previous:(BAUserTagCollections*)previousCollections
{
    self = [super init];
    if (self) {
        [self computeWithNewTagCollections:newCollections previous:previousCollections];
    }
    return self;
}

- (BOOL)hasChanges
{
    return self.added.count != 0 || self.removed.count != 0;
}

- (void)computeWithNewTagCollections:(BAUserTagCollections*)newCollections previous:(BAUserTagCollections*)previousCollections
{
    // Works quite like the attributes comparaison, with a custom diff for collections that still exist on both sides
    BAMutableUserTagCollections *addedResult = [NSMutableDictionary new];
    // Using the full previous collections as a base brings us missing tags for "free" without having to check a second time
    BAMutableUserTagCollections *removedResult = [previousCollections mutableCopy];
    
    for (NSString *collectionName in newCollections.allKeys) {
        TagSet *addedTags = nil;
        TagSet *removedTags = nil;
        [self diffBetweenNewSet:newCollections[collectionName] andOld:previousCollections[collectionName] outAdded:&addedTags outRemoved:&removedTags];
        
        if (addedTags != nil) {
            addedResult[collectionName] = addedTags;
        }
        
        if (removedTags != nil) {
            removedResult[collectionName] = removedTags;
        } else {
            [removedResult removeObjectForKey:collectionName];
        }
    }
    
    _added = addedResult;
    _removed = removedResult;
}

- (void)diffBetweenNewSet:(TagSet*)newSet andOld:(TagSet*)oldSet outAdded:(TagSet**)outAdded outRemoved:(TagSet**)outRemoved
{
    *outAdded = nil;
    *outRemoved = nil;
    // Quick optimizations for common tag collection use cases
    if ([newSet count] == 0) {
        if ([oldSet count] == 0) {
            return;
        } else {
            *outRemoved = [oldSet copy];
            return;
        }
    } else if ([oldSet count] == 0) {
        *outAdded = [newSet copy];
        return;
    } else if (newSet != nil && oldSet != nil && [newSet isEqualToSet:oldSet]) {
        return;
    }
    
    NSMutableSet<NSString*> *missingEntries = [oldSet mutableCopy];
    NSMutableSet<NSString*> *addedEntries = [NSMutableSet new];
    
    for (NSString *entry in newSet) {
        if ([oldSet containsObject:entry]) {
            [missingEntries removeObject:entry];
        } else {
            [addedEntries addObject:entry];
        }
    }
    
    if ([addedEntries count] > 0) {
        *outAdded = addedEntries;
    }
    if ([missingEntries count] > 0) {
        *outRemoved = missingEntries;
    }
}

@end


@implementation BAUserDataDiffTransformer

+ (NSDictionary*)eventParametersFromAttributes:(BAUserAttributesDiff*)attributesDiff
                                tagCollections:(BAUserTagCollectionsDiff*)tagCollectionsDiff
                                       version:(NSNumber*)version
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:4];
    
    result[@"version"] = version;
    
    NSMutableDictionary *added = [NSMutableDictionary dictionaryWithCapacity:(attributesDiff.added.count + tagCollectionsDiff.added.count)];
    NSMutableDictionary *removed = [NSMutableDictionary dictionaryWithCapacity:(attributesDiff.removed.count + tagCollectionsDiff.removed.count)];
    
    
    [added addEntriesFromDictionary:[BAUserAttribute serverJsonRepresentationForAttributes:attributesDiff.added]];
    [removed addEntriesFromDictionary:[BAUserAttribute serverJsonRepresentationForAttributes:attributesDiff.removed]];
    
    
    BAUserTagCollections *addedTagsDiff = tagCollectionsDiff.added;
    for (NSString *name in addedTagsDiff.allKeys) {
        added[[@"t." stringByAppendingString:name]] = addedTagsDiff[name].allObjects;
    }
    
    BAUserTagCollections *removedTagsDiff = tagCollectionsDiff.removed;
    for (NSString *name in removedTagsDiff.allKeys) {
        removed[[@"t." stringByAppendingString:name]] = removedTagsDiff[name].allObjects;
    }
    
    result[@"added"] = added;
    result[@"removed"] = removed;
    
    return result;
}

@end
