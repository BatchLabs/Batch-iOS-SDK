//
//  BANullHelper.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BANullHelper : NSObject

+ (BOOL)isArrayEmpty:(id)object;

+ (BOOL)isDataEmpty:(id)object;

+ (BOOL)isDictionaryEmpty:(id)object;

+ (BOOL)isStringEmpty:(id)object;

+ (BOOL)isNumberEmpty:(id)object;

+ (BOOL)isNull:(id)object;

@end
