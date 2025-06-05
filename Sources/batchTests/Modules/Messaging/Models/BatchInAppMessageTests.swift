//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import SampleShared
import Testing

struct BatchInAppMessageTests {
    @Suite("MEP message")
    struct MEP {
        @Test func content() throws {
            let payload = try #require(BatchMessaging.message(fromPushPayload: ThemePayloadHelper.mepPayload)).messagePayload
            let message = try #require(BatchInAppMessage(forPayload: payload, isCEPMessage: false))

            #expect(message.mepContent != nil)
        }

        @Test func contentType() throws {
            let payload = try #require(BatchMessaging.message(fromPushPayload: ThemePayloadHelper.mepPayload)).messagePayload
            let message = try #require(BatchInAppMessage(forPayload: payload, isCEPMessage: false))

            #expect(message.contentType == .interstitial)
        }
    }

    @Suite("CEP message")
    struct CEP {
        @Test func content() throws {
            let payload = try #require(BatchMessaging.message(fromPushPayload: ThemePayloadHelper.cepPayload)).messagePayload
            let message = try #require(BatchInAppMessage(forPayload: payload, isCEPMessage: true))

            #expect(message.mepContent == nil)
        }

        @Test func contentType() throws {
            let payload = try #require(BatchMessaging.message(fromPushPayload: ThemePayloadHelper.cepPayload)).messagePayload
            let message = try #require(BatchInAppMessage(forPayload: payload, isCEPMessage: true))

            #expect(message.contentType == .unknown)
        }
    }
}
