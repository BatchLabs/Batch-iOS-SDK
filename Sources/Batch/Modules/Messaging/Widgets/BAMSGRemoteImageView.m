#import <Batch/BAMSGRemoteImageView.h>
#import <Batch/BAThreading.h>
#import <Batch/BALogger.h>
#import <Batch/BATGIFFile.h>
#import <Batch/BATGIFAnimator.h>

@interface BAMSGRemoteImageView () <BATGIFAnimatorDelegate>
{
    BATGIFAnimator *_animator;
    UIActivityIndicatorView *_activityIndicator;
    void (^_gifDidLoadCompletion)(UIImage *, NSError *);
}

@end

@implementation BAMSGRemoteImageView

- (void)setup
{
    [super setup];
        
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [_activityIndicator hidesWhenStopped];
    [self addSubview:_activityIndicator];
    
    [_activityIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // Center activity indicator
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:0 toItem:_activityIndicator attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint: [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:0 toItem:_activityIndicator attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
}

- (void)setImageURL:(NSURL *)url {
    [self setImageURL:url completion:nil];
}

- (void)setImageURL:(NSURL*)url completion:(void (^)(UIImage *, NSError *))completion
{
    if (url == nil) {
        if (completion != nil) {
            completion(nil, nil);
        }
        return;
    }
    
    [_activityIndicator startAnimating];
    
    [BAMSGImageDownloader downloadImageForURL:url
                              downloadTimeout:20
                            completionHandler:^(NSData * _Nullable data, BOOL isGif, UIImage * _Nullable image, NSError * _Nullable error) {
                                if (error != nil) {
                                    [BALogger debugForDomain:@"BAMSGRemoteImageView" message:@"Failed to load image: '%@'", error.localizedDescription];
                                    if (completion != nil) {
                                        [BAThreading performBlockOnMainThreadAsync:^{
                                            completion(nil, error);
                                        }];
                                    }
                                    return;
                                }
                                
                                if (isGif) {
                                    [self loadGifAsync:data completion:completion];
                                    [BAThreading performBlockOnMainThreadAsync:^{
                                        [self->_activityIndicator stopAnimating];
                                    }];
                                    return;
                                }
                                
                                if (image != nil) {
                                    [BAThreading performBlockOnMainThreadAsync:^{
                                        if (self.image == nil) {
                                            CATransition *transition = [CATransition animation];
                                            transition.type = kCATransitionFade;
                                            transition.duration = 0.5;
                                            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                                            [self.layer addAnimation:transition forKey:nil];
                                        }
                                        self.image = image;
                                        if (completion != nil) {
                                            completion(image, nil);
                                        }
                                    }];
                                } else if (completion != nil) {
                                    [BAThreading performBlockOnMainThreadAsync:^{
                                        completion(nil, nil);
                                    }];
                                }
                                [BAThreading performBlockOnMainThreadAsync:^{
                                    [self->_activityIndicator stopAnimating];
                                }];
                            }];
}

- (void)loadGifAsync:(NSData*)gifData completion:(void (^_Nonnull)(UIImage *, NSError *))completion
{
    if (!gifData) {
        completion(nil, nil);
        return;
    }
    
    __weak BAMSGRemoteImageView *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *err = nil;
        BATGIFFile *gifFile = [[BATGIFFile alloc] initWithData:gifData error:&err];
        
        if (gifFile == nil) {
            [BALogger debugForDomain:@"Messaging" message:@"Could not load gif file: (%lu) %@", err ? (long) err.code : 0, err ? err.localizedDescription : @"unknown"];
            // Try to fall back on a static UIImage
            UIImage *img = [UIImage imageWithData:gifData];
            if (img != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.image = img;
                    completion(img, nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, err);
                });
            }
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            BAMSGRemoteImageView *strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf->_gifDidLoadCompletion = completion;
                BATGIFAnimator *animator = [[BATGIFAnimator alloc] initWithFile:gifFile];
                animator.delegate = strongSelf;
                strongSelf->_animator = animator;
                [animator startAnimating];
            }
        });
    });
}

- (void)animator:(BATGIFAnimator *)animator needsToDisplayImage:(UIImage *)image
{
    if (_gifDidLoadCompletion != nil) {
        // gif is considered "loaded" on display of first UIImage.
        _gifDidLoadCompletion(image, nil);
        _gifDidLoadCompletion = nil;
    }
    self.image = image;
}

@end
