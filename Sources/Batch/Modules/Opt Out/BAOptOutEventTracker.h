//
//  BAOptOutEventTracker.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAEvent.h>
#import <Batch/BAPromise.h>

/**
 Event tracker that works for opt-out purposes.
 Differences with the "classic" event tracker:
  - It works when opted out
  - It can notify the caller when an event HAS been tracked (meaning that the server _accepted_ it)
  - It doesn't store anything on disk, and does not retry on failure
 */
@interface BAOptOutEventTracker : NSObject

- (BAPromise *)track:(BAEvent *)event;

@end
