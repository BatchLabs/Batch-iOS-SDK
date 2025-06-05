//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

struct InAppWaitingForTests {
    static func wait(for timeInterval: TimeInterval = 2) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
                continuation.resume()
            }
        }
    }
}
