#import <Batch/BADBGNameValueListItem.h>

@implementation BADBGNameValueCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:reuseIdentifier];
    return self;
}

@end

@implementation BADBGNameValueListItem

+ (instancetype)itemWithName:(NSString *)name value:(NSString *)value
{
    BADBGNameValueListItem *item = [[BADBGNameValueListItem alloc] init];
    item.name = name;
    item.value = value;
    return item;
}

@end
