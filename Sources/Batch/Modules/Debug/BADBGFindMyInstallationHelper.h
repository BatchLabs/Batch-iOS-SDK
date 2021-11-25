#import <Foundation/Foundation.h>

@interface BADBGFindMyInstallationHelper : NSObject

@property (class) BOOL enablesFindMyInstallation;

- (nonnull instancetype)initWithPasteboard:(nonnull UIPasteboard*)pasteboard;

@end
