//
//  BAUserAttribute.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAUserDataEnums.h>

@interface BAUserAttribute : NSObject

+ (nonnull instancetype)attributeWithValue:(nonnull id)value type:(BAUserAttributeType)type;

+ (nonnull NSDictionary<NSString *, id> *)serverJsonRepresentationForAttributes:
    (nullable NSDictionary<NSString *, BAUserAttribute *> *)attributes;

@property (nonatomic, nonnull) id value;

@property (assign, nonatomic) BAUserAttributeType type;

@end

typedef NSDictionary<NSString *, BAUserAttribute *> BAUserAttributes;
typedef NSDictionary<NSString *, NSSet<NSString *> *> BAUserTagCollections;
