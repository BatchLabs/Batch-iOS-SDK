#import <Batch/BATGIFFile.h>

#import <MobileCoreServices/MobileCoreServices.h>

// Simple macro that prevents from setting and error and forgetting to return
#define BAIL(err) *error = err; \
return false;

/**
 Minimum duration of a frame
 Took this from FLAnimated image, which sourced it from a blog that experimented with various browsers
 */
const NSTimeInterval kBATGIFFrameMinimumDuration = 0.02;

/**
 Default duration of a frame if CoreGraphics didn't return one
 100ms is the industry default
 */
const NSTimeInterval kBATGIFFrameDefaultDuration = 0.1;

@implementation BATGIFFrame

- (instancetype)initWithSourceIndex:(size_t)index duration:(NSTimeInterval)duration {
    self = [super init];
    if (self) {
        _sourceIndex = index;
        _duration = duration;
    }
    return self;
}

- (BOOL)cached {
    return self.image != nil;
}

@end

@interface BATGIFFile ()
{
    CGImageSourceRef _imageSource;
    NSMutableArray<BATGIFFrame*> *_frames; // Frame cache. Once the initial setup has finished, only the dedicated serial queue should manage the UIImages
    BATGIFCacheSize _cacheSize;
    dispatch_queue_t _cacheQueue;
    NSMutableIndexSet *_indexesScheduledForPreloading; // Indexes that the worker has been asked to preload. MUST ONLY BE mutated by the main thread.
}

@end

@implementation BATGIFFile

#pragma mark Public methods

/**
 Checks if the given NSData might be a gif
 
 Note: this is a quick check. -initWithData:error: might still fail.
 */
+ (BOOL)isPotentiallyAGif:(NSData*)data
{
    if ([data length] > 6) {
        char magic[7]; // +1 for \0
        [data getBytes:&magic length:6];
        magic[sizeof(magic)-1] = '\0';
        if (strcmp("GIF87a", magic) == 0 ||
            strcmp("GIF89a", magic) == 0)
        {
            return true;
        }
    }
    return false;
}

- (instancetype)initWithData:(NSData*)data error:(NSError**)error
{
    self = [super init];
    if (self) {
        if (![self setupWithData:(NSData*)data error:error]) {
            return nil;
        }
    }
    return self;
}

- (BATGIFFrame*)frameAtIndex:(NSUInteger)index
{
    return _frames[index];
}

- (void)consumeFrameAtIndex:(NSUInteger)index
{
    if (_cacheQueue) {
        _frames[index].image = nil;
    }
    return;
}

- (void)willDisplayFrameAtIndex:(NSUInteger)index
{
    if (_cacheQueue) {
        __weak BATGIFFile *weakSelf = self;
        NSArray *indexesSupposedToPreload = [self indexesToPreloadWithStartingIndex:index];
        // Look at all the indexes we should add to the queue, and skip jobs that already are scheduled
        // The main thread will be our coordinator in all of this
        for (NSNumber *nbIndex in indexesSupposedToPreload) {
            NSUInteger index = nbIndex.unsignedIntegerValue;
            if (![_indexesScheduledForPreloading containsIndex:index]) {
                [_indexesScheduledForPreloading addIndex:index];
                
                dispatch_async(_cacheQueue, ^{
                    BATGIFFile *unboxedSelf = weakSelf;
                    if (unboxedSelf && [unboxedSelf->_indexesScheduledForPreloading containsIndex:index]) {
                        BATGIFFrame *frame = unboxedSelf->_frames[index];
                        UIImage *loadedImage = [unboxedSelf produceFrameAtSourceIndex:frame.sourceIndex];
                        if (loadedImage) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [unboxedSelf setCachedImage:loadedImage atIndex:index];
                            });
                        }
                    }
                });
            }
        }
    }
    return;
}

#pragma mark GIF Parsing

- (BOOL)setupWithData:(NSData*)data error:(NSError**)error
{
    // Replace error with a dummy variable if it's null, so we don't have to check each time
    if (error == NULL) {
        __autoreleasing NSError *fakeOutErr;
        error = &fakeOutErr;
    }
    *error = nil;
    
    // Listen to memory warning notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    
    _cacheSize = BATGIFCacheSizeUndefined;
    
    _imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data,
                                               (__bridge CFDictionaryRef)@{(NSString*)kCGImageSourceShouldCache: @(false)});
    
    if (!_imageSource) {
        BAIL([self errorWithCode:BATGIFErrorCouldNotCreateImageSource message:@"Could not create image source"]);
    }
    
    // Check if this is a GIF
    if (!UTTypeConformsTo(CGImageSourceGetType(_imageSource), kUTTypeGIF)) {
        BAIL([self errorWithCode:BATGIFErrorNotAGif message:@"Image is not a GIF"]);
    }
    
    // Iterate over all frames in the gif, extracting the duration
    // Don't store the raw frame count in _framesCount just yet, as we will only count the VALID frames (aka ones that CoreGraphics was able to decode)
    // We can still use the frame count to initialize the structures as the difference should be slim (if any)
    
    size_t sourceFrameCount = CGImageSourceGetCount(_imageSource);
    _frames = [[NSMutableArray alloc] initWithCapacity:sourceFrameCount];
    
    NSUInteger insertedFrameIndex = 0;
    NSTimeInterval previousDuration = kBATGIFFrameDefaultDuration;
    BATGIFFrame *decodedFrame;
    @autoreleasepool {
        for (size_t i = 0; i < sourceFrameCount; i++) {
            decodedFrame = [self frameForIndex:i previousDuration:previousDuration];
            if (decodedFrame != nil) {
                previousDuration = decodedFrame.duration;
                // We need a valid image to compute the cache strategy, as we can now know the number of bytes per frame
                if (_cacheSize == BATGIFCacheSizeUndefined) {
                    [self computeCacheStrategyUsingReferenceFrame:decodedFrame
                                                   expectedFrames:sourceFrameCount];
                } else if (_cacheSize != BATGIFCacheSizeNoCache) {
                    if (insertedFrameIndex >= _cacheSize) {
                        // We're over the cache, purge the image
                        decodedFrame.image = nil;
                    }
                }
                [_frames addObject:decodedFrame];
                insertedFrameIndex++;
            }
        }
    }
    _frameCount = [_frames count];
    
    [self recomputeCacheStrategyWithRealFrameCount:_frameCount];
    
    return true;
}

// Get a frame out from the raw source index
// This should only be done once and cached
- (BATGIFFrame*)frameForIndex:(size_t)index previousDuration:(NSTimeInterval)previousDuration
{
    // Decode a UIImage from the frame, to make sure it can be decoded later
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_imageSource, index, NULL);
    if (imageRef == NULL) {
        return nil;
    }
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    if (image == nil) {
        return nil;
    }
    
    // Extract the properties (gif specific stuff is in a sub dictionary)
    NSDictionary *frameProperties = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(_imageSource, index, NULL);
    NSDictionary *gifProperties = frameProperties[(NSString*)kCGImagePropertyGIFDictionary];
    if (![gifProperties isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    // Compute the duration (called DelayTime)
    // First, try to read the unclamped delay time
    // Fall back on the normal delay time
    // Fall back on the previous duration
    //    Which will itself should be the default duration for the first frame, but that's
    //    handled elsewhere
    // Then, make sure we don't go lower than the minimum duration
    
    NSNumber *delayTime = gifProperties[(NSString*)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTime == nil) {
        delayTime = gifProperties[(NSString*)kCGImagePropertyGIFDelayTime];
    }
    
    NSTimeInterval duration;
    if (delayTime != nil) {
        duration = [delayTime doubleValue];
    } else {
        duration = previousDuration;
    }
    
    duration = MAX(kBATGIFFrameMinimumDuration, duration);
    
    BATGIFFrame *frame = [[BATGIFFrame alloc] initWithSourceIndex:index duration:duration];
    frame.image = image;
    
    return frame;
}

/**
 Compute the cache strategy according to the size we expect to take all bitmaps to fit in memory
 */
- (void)computeCacheStrategyUsingReferenceFrame:(BATGIFFrame*)decodedFrame
                                 expectedFrames:(size_t)sourceFrameCount
{
    if (decodedFrame.image == nil) {
        return;
    }
    
    CGImageRef cgImg = decodedFrame.image.CGImage;
    // Compute size used in MB
    double expectedUncompressedSize = (sourceFrameCount * (CGImageGetBytesPerRow(cgImg) * CGImageGetHeight(cgImg))) / (1024*1024);
    [BALogger debugForDomain:@"GIF" message:@"Expecting GIF to take %f MBs", expectedUncompressedSize];
    
    //TODO make something dynamic based on the free ram
    
    NSUInteger gifSizeThreshold;
    // Tweak the cache settings according to the available RAM
    NSUInteger availableRam = (NSUInteger)(NSProcessInfo.processInfo.physicalMemory / 1024 / 1024);
    if (availableRam > 2000) {
        gifSizeThreshold = 60;
    } else if (availableRam > 1000) {
        gifSizeThreshold = 45;
    } else if (availableRam > 512) {
        gifSizeThreshold = 25;
    } else {
        gifSizeThreshold = 15;
    }
    
    if (expectedUncompressedSize >= gifSizeThreshold) {
        _cacheSize = BATGIFCacheSizeNormal;
        [BALogger debugForDomain:@"GIF" message:@"Cache enabled"];
    } else {
        _cacheSize = BATGIFCacheSizeNoCache;
        [BALogger debugForDomain:@"GIF" message:@"Cache disabled"];
    }
    
    [self setupCacheIfNeeded];
}

/**
 Check if the cache is still needed.
 
 If the cache is bigger than the total number of frames, we will waste a lot of time redecoding frames
 So, disable the cache rather than adding complicated logic everywhere else
 */
- (void)recomputeCacheStrategyWithRealFrameCount:(NSUInteger)frameCount
{
    if (_cacheSize >= frameCount) {
        _cacheSize = BATGIFCacheSizeNoCache;
        _cacheQueue = nil;
        _indexesScheduledForPreloading = nil;
        
        // For safety, make sure we have all images loaded
        for (BATGIFFrame *frame in _frames) {
            frame.image = [self produceFrameAtSourceIndex:frame.sourceIndex];
        }
    }
}

/**
 Generate a frame for the specified index, and save it in the cache
 
 Must not be called on the main thread
 */
- (UIImage*)produceFrameAtSourceIndex:(size_t)sourceIndex
{
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_imageSource, sourceIndex, NULL);
    if (imageRef == NULL) {
        [BALogger debugForDomain:@"GIF" message:@"Couldn't cache frame %lu", (unsigned long)sourceIndex];
        return false;
    }
    UIImage *img = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return img;
}

#pragma mark Cache

- (void)setupCacheIfNeeded
{
    if (_cacheSize != BATGIFCacheSizeNoCache) {
        if (!_cacheQueue) {
            _cacheQueue = dispatch_queue_create("com.batch.gif.cache_worker", DISPATCH_QUEUE_SERIAL);
        }
        
        if (!_indexesScheduledForPreloading) {
            _indexesScheduledForPreloading = [NSMutableIndexSet new];
        }
    }
}

- (void)setCachedImage:(UIImage*)image atIndex:(NSUInteger)index
{
    _frames[index].image = image;
    [_indexesScheduledForPreloading removeIndex:index];
}

/**
 Return the ordered indexes to preload
 */
- (NSArray*)indexesToPreloadWithStartingIndex:(NSUInteger)index
{
    if (_cacheSize <= 0) {
        return nil;
    }
    
    NSArray *indexes;
    
    // We want to preload starting from the next frame while respecting the cache size
    // Note: this could be rewritten without the ranges, and only the modulo. I kept that in the meantime so I could switch to another datastructure easily.
    NSUInteger startIndex = [self incrementIndex:index by:1];
    NSUInteger endIndex = [self incrementIndex:index by:_cacheSize];
    
    if (startIndex == endIndex) {
        indexes = @[@(startIndex)];
    } else if (endIndex >= startIndex) {
        NSMutableArray *mutableIndexes = [[NSMutableArray alloc] initWithCapacity:_cacheSize];
        for (NSUInteger i = startIndex; i < endIndex + 1; i++) {
            [mutableIndexes addObject:@(i)];
        }
        indexes = mutableIndexes;
    } else {
        // We need to manually make the two ranges, from startIndex to the end, and from 0 to endIndex
        NSMutableArray *mutableIndexes = [[NSMutableArray alloc] initWithCapacity:_cacheSize];
        for (NSUInteger i = startIndex; i < _frameCount; i++) {
            [mutableIndexes addObject:@(i)];
        }
        for (NSUInteger i = 0; i < endIndex + 1; i++) {
            [mutableIndexes addObject:@(i)];
        }
        indexes = mutableIndexes;
    }
    
    if (indexes.count > _cacheSize) {
        [BALogger debugForDomain:@"GIF" message:@"Trying to cache too many frames (%lu)", (unsigned long)[indexes count]];
    }
    
    return indexes;
}

/**
 Increment the index, looping if necessary
 */
- (NSUInteger)incrementIndex:(NSUInteger)index by:(NSUInteger)byValue
{
    return (index + byValue) % _frameCount;
}

#pragma mark Lifecycle

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    switch (_cacheSize) {
        case BATGIFCacheSizeNoCache:
            [BALogger debugForDomain:@"GIF" message:@"Memory warning: Turning on cache"];
            _cacheSize = BATGIFCacheSizeNormal;
            break;
        case BATGIFCacheSizeNormal:
            [BALogger debugForDomain:@"GIF" message:@"Memory warning: Reducing cache size"];
            _cacheSize = BATGIFCacheSizeSmall;
            break;
        default:
            return;
    }
    
    [self setupCacheIfNeeded];
    // Purge the cache to free up memory ASAP. The animator will fix this up itself
    for (BATGIFFrame *frame in _frames) {
        frame.image = nil;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
    
    if (_cacheQueue) {
        _cacheQueue = NULL;
    }
}

#pragma mark Error helper
- (NSError*)errorWithCode:(BATGIFError)error message:(NSString*)message
{
    return [NSError errorWithDomain:@"com.batch.gif"
                               code:error
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

@end
