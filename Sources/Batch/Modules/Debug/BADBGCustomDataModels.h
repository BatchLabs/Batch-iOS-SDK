#import <Foundation/Foundation.h>

@interface BADBGCustomDataTagCollection : NSObject

@property NSString *collectionName;
@property NSArray<NSString*> *tags;

@end

@interface BADBGCustomDataAttribute : NSObject

@property NSString *name;
@property NSString *value;

+ (instancetype)attributeWithName:(NSString *)name value:(NSString *)value;

@end
