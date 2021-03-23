#import <Batch/BADBGModule.h>

#import <Batch/BADBGDebugViewController.h>

@implementation BADBGModule

+ (UIViewController*)debugViewController
{
    return [[UINavigationController alloc] initWithRootViewController:[BADBGDebugViewController new]];
}

@end
