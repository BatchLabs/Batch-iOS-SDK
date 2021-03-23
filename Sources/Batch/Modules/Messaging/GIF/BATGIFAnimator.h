#import <Foundation/Foundation.h>
#import <Batch/BATGIFFile.h>

NS_ASSUME_NONNULL_BEGIN

@class BATGIFAnimator;

@protocol BATGIFAnimatorDelegate <NSObject>

@required
- (void)animator:(BATGIFAnimator*)animator needsToDisplayImage:(UIImage*)image;

@end

@interface BATGIFAnimator : NSObject

@property (weak) id<BATGIFAnimatorDelegate> delegate;

@property NSUInteger framerate;

- (instancetype)initWithFile:(BATGIFFile*)file;

- (void)startAnimating;

- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
