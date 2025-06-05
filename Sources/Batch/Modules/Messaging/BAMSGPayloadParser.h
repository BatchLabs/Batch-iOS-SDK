//
//  BAMSGPayloadParser.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGMessage.h>
#import <Foundation/Foundation.h>

@interface BAMSGPayloadParser : NSObject

+ (BAMSGMEPMessage *_Nullable)messageForMEPRawMessage:(BatchMessage *_Nonnull)rawMessage
                                       bailIfNotAlert:(BOOL)bailNotAlert;
+ (BAMSGCEPMessage *_Nullable)messageForCEPRawMessage:(BatchMessage *_Nonnull)rawMessage
                                       bailIfNotAlert:(BOOL)bailNotAlert;
@end
