//
//  BatchMessagingCloseReason.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

// Determin the different reasons why an In-App message can be closed
typedef NS_CLOSED_ENUM(NSUInteger, BatchMessagingCloseReason) {
    // The message was closed automatically from auto dismiss feature.
    BatchMessagingCloseReasonAuto,
    // The message was closed by the user (like clicking on the close or back button).
    BatchMessagingCloseReasonUser,
    // The message was closed because the user clicked on a CTA.
    BatchMessagingCloseReasonAction,
    // The message was closed because of an error
    // (for example, a message with only one image in it that fails to be downloaded).
    BatchMessagingCloseReasonError
};
