//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BADictionaryHelper : NSObject

+ (BOOL)dictionary:(NSDictionary *)actual containsValuesFromDictionary:(NSDictionary *)expected;

+ (BOOL)array:(NSArray *)actual containsValuesFromArray:(NSArray *)expected;

@end
