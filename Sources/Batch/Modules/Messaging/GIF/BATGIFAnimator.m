#import <Batch/BATGIFAnimator.h>

/**
 Simple proxy that allows CADisplayLink's target to be weakly retained
 Otherwise, we have a retain cycle between the animator and the DisplayLink
 */
@interface BATGIFDisplayLinkProxy : NSObject

@property (weak) BATGIFAnimator *animator;

- (instancetype)initWithAnimator:(BATGIFAnimator *)animator;

- (void)displayDidRefresh:(CADisplayLink *)displayLink;

@end

@interface BATGIFAnimator () {
    BATGIFFile *_file;
    CADisplayLink *_displayLink;

    BOOL _shouldAnimate;
    NSUInteger _currentFrameIndex;
    BATGIFFrame *_currentFrame;
    NSTimeInterval _elapsedTimeSinceLastFrame; // Count the elapsed time in between each frame. Even if a frame hasn't
                                               // been displayed (because the decoder might be running late), we still
                                               // increment this, so that we can skip problematic frames.
    BOOL _needsDisplayWhenPossible; // Flag indicating that we need to display the current frame's image when possible.
                                    // This allows images to be decoded too late, as they will be reattempted at the
                                    // next CADisplayLink tick
    CFTimeInterval _lastTimestamp;  // Last timestamp at which a frame was displayed according to CADisplayLink
}

@end

@implementation BATGIFAnimator

#pragma mark Public methods

- (instancetype)initWithFile:(BATGIFFile *)file {
    self = [super init];
    if (self) {
        _file = file;
        _shouldAnimate = false;
        _currentFrameIndex = 0;
        _currentFrame = [_file frameAtIndex:_currentFrameIndex];
        _framerate = 60;
        if (NSProcessInfo.processInfo.lowPowerModeEnabled) {
            _framerate = 30;
        }
    }
    return self;
}

- (void)startAnimating {
    if (_shouldAnimate) {
        return;
    }

    _shouldAnimate = true;

    if (!_displayLink) {
        // DisplayLink strongly retains the target
        _displayLink = [CADisplayLink displayLinkWithTarget:[[BATGIFDisplayLinkProxy alloc] initWithAnimator:self]
                                                   selector:@selector(displayDidRefresh:)];
        _displayLink.preferredFramesPerSecond = _framerate;
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }

    _lastTimestamp = 0;
    _needsDisplayWhenPossible = true;
    _displayLink.paused = false;
}

- (void)stopAnimating {
    if (!_shouldAnimate) {
        return;
    }

    _shouldAnimate = false;
    _displayLink.paused = true;
}

#pragma mark Private methods

- (void)moveToNextFrame {
    _currentFrameIndex++;
    if (_currentFrameIndex >= _file.frameCount) {
        _currentFrameIndex = 0;
    }
    _currentFrame = [_file frameAtIndex:_currentFrameIndex];
}

#pragma mark CADisplayLink events

- (void)displayDidRefresh:(CADisplayLink *)displayLink {
    if (!_shouldAnimate) {
        return;
    }

    CFTimeInterval dlTimestamp = displayLink.timestamp;
    if (_lastTimestamp > 0) {
        _elapsedTimeSinceLastFrame += dlTimestamp - _lastTimestamp;
    }
    _lastTimestamp = dlTimestamp;

    // Store the image in a variable, as consuming it might remove its reference
    if (_needsDisplayWhenPossible) {
        UIImage *currentFrameImage = _currentFrame.image;
        if (currentFrameImage != nil) {
            [_file consumeFrameAtIndex:_currentFrameIndex];
            [_delegate animator:self needsToDisplayImage:currentFrameImage];
            _needsDisplayWhenPossible = false;
        } else {
            [BALogger
                debugForDomain:@"GIF"
                       message:@"Expected frame %lu to be there, but it's not.", (unsigned long)_currentFrameIndex];
        }
    }

    // While-loop first inspired by & good Karma to: FLAnimatedImageView and
    // https://github.com/ondalabs/OLImageView/blob/master/OLImageView.m What is basically does, is increment the frames
    // until we caught up. Skipping too many frames might put the cache in a tough situation, so warn the file to warm
    // up the next ones
    NSTimeInterval duration = _currentFrame.duration;
    while (_elapsedTimeSinceLastFrame >= duration) {
        // Remove the duration of this frame from the accumulator, and move to the next one
        _elapsedTimeSinceLastFrame -= duration;
        [self moveToNextFrame];
        duration = _currentFrame.duration;
        _needsDisplayWhenPossible = true;
    }

    // Only ask the cache to preload ahead if we moved frames
    if (_needsDisplayWhenPossible) {
        [_file willDisplayFrameAtIndex:_currentFrameIndex];
    }
}

#pragma mark Lifecycle

- (void)dealloc {
    [_displayLink invalidate];
}

@end

@implementation BATGIFDisplayLinkProxy

- (instancetype)initWithAnimator:(BATGIFAnimator *)animator {
    self = [super init];
    if (self) {
        _animator = animator;
    }
    return self;
}

- (void)displayDidRefresh:(CADisplayLink *)displayLink {
    [_animator displayDidRefresh:displayLink];
}

@end
