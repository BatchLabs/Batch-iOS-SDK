//
//  BAMessagingAnalyticsDelegate.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMSGMessage.h>

#import <Batch/BAMSGAction.h>

#import <Batch/BATMessagingCloseErrorCause.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BAMessagingAnalyticsDelegate

- (void)messageShown:(BAMSGMessage *_Nonnull)message;

- (void)messageClosed:(BAMSGMessage *_Nonnull)message;

- (void)message:(BAMSGMessage *_Nonnull)message
    closedByError:(BATMessagingCloseErrorCause)cause NS_SWIFT_NAME(messageClosed(_:byError:));

- (void)messageDismissed:(BAMSGMessage *_Nonnull)message;

- (void)messageButtonClicked:(BAMSGMessage *_Nonnull)message
               ctaIdentifier:(NSString *_Nonnull)ctaIdentifier
                      action:(BAMSGCTA *)action;

- (void)messageButtonClicked:(BAMSGMessage *_Nonnull)message
               ctaIdentifier:(NSString *)ctaIdentifier
                     ctaType:(NSString *)ctaType
                      action:(BAMSGAction *)action;

- (void)messageAutomaticallyClosed:(BAMSGMessage *_Nonnull)message;

- (void)messageGlobalTapActionTriggered:(BAMSGMessage *_Nonnull)message action:(BAMSGAction *)action;

- (void)messageWebViewClickTracked:(BAMSGMessage *_Nonnull)message
                            action:(BAMSGAction *)action
               analyticsIdentifier:(NSString *)analyticsID;

@end

NS_ASSUME_NONNULL_END
