//
//  BAJson.h
//  Batch
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @class BAJson
 @abstract Static class to serialize and deserialize JSON and BSON
 */
@interface BAJson : NSObject

/**
 Serialize a Foundation object into a NSString.
 */
+ (nullable NSString *)serialize:(nonnull id)object error:(NSError **)error;

/**
 Serialize a Foundation object into a NSData.
 */
+ (nullable NSData *)serializeData:(nonnull id)object error:(NSError **)error;

/**
 Deserialize a JSON NSString into a Foundation object.
 */
+ (nullable id)deserialize:(nonnull NSString *)json error:(NSError **)error;

/**
 Deserialize a JSON NSString into a NSArray.
 */
+ (nullable NSArray *)deserializeAsArray:(nonnull NSString *)json error:(NSError **)error;

/**
 Deserialize a JSON NSString into a NSDictionary.
 */
+ (nullable NSDictionary *)deserializeAsDictionary:(nonnull NSString *)json error:(NSError **)error;

/**
 Deserialize a JSON NSData into a Foundation object.
 */
+ (nullable id)deserializeData:(nonnull NSData *)jsonData error:(NSError **)error;

/**
 Deserialize a JSON NSData into a NSArray.
 */
+ (nullable NSArray *)deserializeDataAsArray:(nonnull NSData *)jsonData error:(NSError **)error;

/**
 Deserialize a JSON NSData into a NSDictionary.
 */
+ (nullable NSDictionary *)deserializeDataAsDictionary:(nonnull NSData *)jsonData error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
