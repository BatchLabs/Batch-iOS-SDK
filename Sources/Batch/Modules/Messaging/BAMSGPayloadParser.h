//
//  BAMSGPayloadParser.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGMessage.h>
#import <Foundation/Foundation.h>

@interface BAMSGPayloadParser : NSObject

+ (BAMSGMessage *_Nullable)messageForRawMessage:(BatchMessage *_Nonnull)rawMessage bailIfNotAlert:(BOOL)bailNotAlert;

@end
