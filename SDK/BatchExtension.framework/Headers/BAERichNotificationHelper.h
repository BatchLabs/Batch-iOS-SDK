//
//  BAERichNotificationHelper.h
//  BatchExtension
//
//  Copyright © 2016 Batch.com. All rights reserved.
//

@import Foundation;
@import UIKit;
@import UserNotifications;

NS_ASSUME_NONNULL_BEGIN

/**
 Batch Extension Rich Notifications helper.
 You should instanciate this once per UNNotificationServiceExtension and use the same instance for everything, as some methods might need context.
 */
@interface BAERichNotificationHelper : NSObject

/**
 Append rich data (image/sound/video/...) to a specified notification content. Batch will automatically download the attachments and add them to the content
 before returning it to you in the completion handler.
 
 This operation can finish after serviceExtensionTimeWillExpire, so be sure to handle this case correctly, and preprocess your content before giving it to this method

 @param content           Notification content
 @param completionHandler Completion block
 */
- (void)appendRichDataToContent:(UNNotificationContent*)content completionHandler:(void (^)(UNNotificationContent* _Nullable result, NSError* _Nullable error))completionHandler;


/**
 Drop-in replacement for UserNotifications' didReceiveNotificationRequest:withContentHandler.
 Feel free to tweak the request or the result before handing it to batch

 @param request        Notification request
 @param contentHandler Callback block
 */
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler;


/**
 Call this to notify Batch that the same method of the standard iOS delegate has been called
 */
- (void)serviceExtensionTimeWillExpire;

@end


/**
 Drop-in replacement for UNNotificationServiceExtension. Simply set it as your base class without overriding any methods and Batch will automatically:
  - Remove duplicate notifications
  - Download and set rich content
 */
@interface BAENotificationServiceExtension : UNNotificationServiceExtension

@end

NS_ASSUME_NONNULL_END
