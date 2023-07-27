#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, BATGIFError) {
    BATGIFErrorCouldNotCreateImageSource, // CoreGraphics failed to create the source
    BATGIFErrorNotAGif,                   // Source is not a GIF
    BATGIFErrorAnimationNotNeeded,        // Animation is not needed (not more than 1 frame)
};

/**
 Cache sizes. Note that an extra frame will be held at all times : the current frame.
 Meaning that if you have a cache size of 2, 3 frames will be held in memory at all times.
 */
typedef NS_ENUM(NSUInteger, BATGIFCacheSize) {
    BATGIFCacheSizeUndefined = -1,
    BATGIFCacheSizeNoCache = 0,
    BATGIFCacheSizeNormal = 10,
    BATGIFCacheSizeSmall = 2,
};

/**
 Represents a GIF frame
 */
@interface BATGIFFrame : NSObject

// Index of that frame in the source image
@property (readonly) size_t sourceIndex;

@property (readonly) NSTimeInterval duration;

@property (strong, nullable) UIImage *image;

/**
 Returns true if the image is available
 */
@property (readonly) BOOL cached;

- (instancetype)initWithSourceIndex:(size_t)index duration:(NSTimeInterval)duration;

@end

/**
 Represents a GIF file, and its extracted frames
 */
@interface BATGIFFile : NSObject

/**
 Checks if the given NSData might be a gif

 Note: this is a quick check. -initWithData:error: might still fail.
 */
+ (BOOL)isPotentiallyAGif:(NSData *)data;

@property (readonly) NSUInteger frameCount; // Number of frames available. This reflects the number of frames we were
                                            // able to decode from the GIF, not the number it told it had

/**
 Make a new BATGIFFile from the given data.
 This is an expensive operation that should not be done on the main thread
 */
- (nullable instancetype)initWithData:(NSData *)data error:(NSError **)error;

/**
 Get the frame at an index.
 */
- (BATGIFFrame *)frameAtIndex:(NSUInteger)index;

/**
 Consume the frame at an index.

 The cache will consider this frame and all the ones before it consumed (if all frames don't fit in memory).
 It is also going to start caching next ones in the background.
 */
- (void)consumeFrameAtIndex:(NSUInteger)index;

/**
 Warn that a frame will be displayed (but not yet consumed).
 The difference between this method and "consumeFrameAtIndex" is that the frame will NOT be attempted to be freed.

 Call this method when you're about to display the frame at the specified index, so that
 this class may take this opportunity to add more in the cache.
 */
- (void)willDisplayFrameAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
