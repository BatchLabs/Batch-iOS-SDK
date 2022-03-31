//
//  BAMSGVideoView.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGVideoView.h>

#import <Batch/BALogger.h>

@import AVFoundation;

@interface BAMSGVideoView () {
    AVPlayer *player;
}
@end

@implementation BAMSGVideoView

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        player = [AVPlayer playerWithURL:url];
        // Disallow airplay, we really want to "sandbox" this
        player.allowsExternalPlayback = NO;
        // Required to loop the video
        player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        // Try not to interrupt the music
        player.muted = YES;

        AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.layer;
        playerLayer.player = player;
        playerLayer.videoGravity = AVLayerVideoGravityResize;
    }
    return self;
}

- (void)viewDidAppear {
    __weak typeof(self) weakSelf = self;
    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
    [notifCenter addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                             object:nil
                              queue:nil
                         usingBlock:^(NSNotification *note) {
                           // holding a pointer to avPlayer to reuse it
                           typeof(self) strongSelf = weakSelf;

                           if (strongSelf) {
                               [strongSelf->player seekToTime:kCMTimeZero];
                               [strongSelf->player play];
                           }
                         }];

    [notifCenter addObserverForName:UIApplicationWillEnterForegroundNotification
                             object:nil
                              queue:nil
                         usingBlock:^(NSNotification *note) {
                           // holding a pointer to avPlayer to reuse it
                           typeof(self) strongSelf = weakSelf;

                           if (strongSelf) {
                               [strongSelf->player play];
                           }
                         }];

    [player seekToTime:kCMTimeZero];
    [player play];
}

- (void)viewDidDisappear {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [player pause];
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)applyRules:(nonnull BACSSRules *)rules {
    [BAMSGStylableViewHelper applyCommonRules:rules toView:self];

    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys]) {
        NSString *value = rules[rule];

        if ([@"scale" isEqualToString:rule]) {
            AVPlayerLayer *playerLayer = (AVPlayerLayer *)self.layer;
            if ([@"fit" isEqualToString:value]) {
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            } else if ([@"fill" isEqualToString:value]) {
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            } else if ([@"resize" isEqualToString:value]) {
                playerLayer.videoGravity = AVLayerVideoGravityResize;
            }
        }
    }
}

@end
