//
//  BatchUserAttributePrivate.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

// Expose private constructors
// This header is private and should NEVER be distributed within the framework

@interface BatchUserAttribute ()
- (nullable instancetype)initWithValue:(nonnull id)value type:(BatchUserAttributeType)type;
@end
