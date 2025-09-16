//
//  BADelegatedUIAlertController.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BADelegatedUIAlertController.h>
#import <Batch/BatchMessagingPrivate.h>

#import <Batch/BAInjection.h>
#import <Batch/BAMessagingCenter.h>

@implementation BADelegatedUIAlertController {
    id<BAMessagingAnalyticsDelegate> _messagingAnalyticsDelegate;
}

+ (instancetype)alertControllerWithMessage:(BAMSGMessageAlert *_Nonnull)message {
    return [[BADelegatedUIAlertController alloc] initWithMessage:message];
}

- (instancetype)initWithMessage:(BAMSGMessageAlert *_Nonnull)message {
    self = [super init];

    if (self) {
        self.messageDescription = message;

        self.title = message.titleText;
        self.message = message.bodyText;

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:message.cancelButtonText
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *_Nonnull action) {
                                                               [self cancelPressed];
                                                             }];
        [self addAction:cancelAction];

        if (message.acceptCTA) {
            UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:message.acceptCTA.label
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                                   [self acceptPressed];
                                                                 }];

            [self addAction:acceptAction];
        }

        _messagingAnalyticsDelegate = [BAInjection injectProtocol:@protocol(BAMessagingAnalyticsDelegate)];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [_messagingAnalyticsDelegate messageShown:self.messageDescription];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [_messagingAnalyticsDelegate messageDismissed:self.messageDescription];
}

- (UIAlertControllerStyle)preferredStyle {
    return UIAlertControllerStyleAlert;
}

- (BOOL)shouldDisplayInSeparateWindow {
    return false;
}

- (void)cancelPressed {
    [self dismissViewControllerAnimated:YES completion:nil];

    [_messagingAnalyticsDelegate messageClosed:self.messageDescription];
}

- (void)acceptPressed {
    [self dismissViewControllerAnimated:YES completion:nil];

    [_messagingAnalyticsDelegate messageButtonClicked:self.messageDescription
                                             ctaIndex:0
                                               action:self.messageDescription.acceptCTA];

    NSString *ctaIndex = [NSString stringWithFormat:@"%i", 0];
    NSString *ctaIdentifier = [BATCH_MESSAGE_MEP_CTA_INDEX_KEY stringByAppendingString:ctaIndex];

    // We don't need to handle BAMSGCTAActionKindClose since we did that earlier
    [BAMessagingCenter.instance performAction:self.messageDescription.acceptCTA
                                       source:self.messageDescription.sourceMessage
                                ctaIdentifier:ctaIdentifier
                            messageIdentifier:self.messageDescription.sourceMessage.devTrackingIdentifier];
}

@end
