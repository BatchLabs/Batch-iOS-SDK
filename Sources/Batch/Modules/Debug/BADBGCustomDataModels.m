#import <Batch/BADBGCustomDataModels.h>

@implementation BADBGCustomDataTagCollection

@end

@implementation BADBGCustomDataAttribute

+ (instancetype)attributeWithName:(NSString *)name value:(NSString *)value {
    BADBGCustomDataAttribute *item = [[BADBGCustomDataAttribute alloc] init];
    item.name = name;
    item.value = value;
    return item;
}

@end
