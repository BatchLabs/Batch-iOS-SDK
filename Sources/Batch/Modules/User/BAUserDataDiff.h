#import <Foundation/Foundation.h>

#import <Batch/BAUserAttribute.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents the difference between two sets of attributes.

 A modified attribute will appear in both "added" and "removed"
 */
@interface BAUserAttributesDiff : NSObject

- (instancetype)initWithNewAttributes:(BAUserAttributes *)newAttributes previous:(BAUserAttributes *)previousAttributes;

- (BOOL)hasChanges;

@property (readonly) BAUserAttributes *added;
@property (readonly) BAUserAttributes *removed;

@end

/**
 Represents the difference between two sets of tag collections.
 */
@interface BAUserTagCollectionsDiff : NSObject

/**
 Diff two string sets

 Optimized for tag collections
 */
- (instancetype)initWithNewTagCollections:(BAUserTagCollections *)newCollections
                                 previous:(BAUserTagCollections *)previousCollections;

- (BOOL)hasChanges;

@property (readonly) BAUserTagCollections *added;
@property (readonly) BAUserTagCollections *removed;

@end

@interface BAUserDataDiffTransformer : NSObject

/**
 Convert attributes and tag collections diff to event parameters suitable for server consumption

 This includes writing the attributes in their "flat" form ("attr_name.type": value)
 */
+ (NSDictionary *)eventParametersFromAttributes:(BAUserAttributesDiff *)attributesDiff
                                 tagCollections:(BAUserTagCollectionsDiff *)tagCollectionsDiff
                                        version:(NSNumber *)version;

@end

NS_ASSUME_NONNULL_END
