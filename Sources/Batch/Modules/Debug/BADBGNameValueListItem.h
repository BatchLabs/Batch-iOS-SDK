#import <UIKit/UIKit.h>

@interface BADBGNameValueCell : UITableViewCell
@end

@interface BADBGNameValueListItem : NSObject

@property NSString *name;
@property NSString *value;

+ (instancetype)itemWithName:(NSString *)name value:(NSString *)value;

@end
