//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import Testing

// Raw dictionaries lock the attributes response wire keys and action vocabulary.

private let queryIdentifier = "B0FA3E0C-4B1F-4F0B-9C4C-1D2E3F4A5B6C"

private func attributesCheckPayload(_ fields: [AnyHashable: Any]) -> [AnyHashable: Any] {
    var payload: [AnyHashable: Any] = ["id": queryIdentifier]
    for (key, value) in fields {
        payload[key] = value
    }
    return payload
}

private struct UnparsableResponse: Error {}

private func makeAttributesCheckResponse(_ fields: [AnyHashable: Any]) throws -> BAWSResponseAttributesCheck {
    guard let response = BAWSResponseAttributesCheck(response: attributesCheckPayload(fields)) else {
        throw UnparsableResponse()
    }
    return response
}

private func makeAttributesResponse(_ fields: [AnyHashable: Any]) throws -> BAWSResponseAttributes {
    guard let response = BAWSResponseAttributes(response: attributesCheckPayload(fields)) else {
        throw UnparsableResponse()
    }
    return response
}

@Suite("Attributes check response")
struct AttributesCheckResponseTests {
    @Test("Action tokens map to their state machine case")
    func actionVocabulary() throws {
        #expect(try makeAttributesCheckResponse(["action": "OK"]).action == .ok)
        #expect(try makeAttributesCheckResponse(["action": "BUMP"]).action == .bump)
        #expect(try makeAttributesCheckResponse(["action": "RECHECK"]).action == .recheck)
        #expect(try makeAttributesCheckResponse(["action": "RESEND"]).action == .resend)
    }

    @Test("Action matching ignores the casing the server used")
    func actionCasing() throws {
        // The action is uppercased before being matched, and the backend does answer in lowercase
        // (see `profileMigrationTests`). Dropping the uppercasing would turn every real answer into
        // `unknown`, i.e. an endless recheck loop.
        #expect(try makeAttributesCheckResponse(["action": "reCheck"]).action == .recheck)
    }

    @Test("Anything outside the vocabulary is the unknown action")
    func unusableActions() throws {
        #expect(try makeAttributesCheckResponse([:]).action == .unknown)
        #expect(try makeAttributesCheckResponse(["action": "DESTROY"]).action == .unknown)
        #expect(try makeAttributesCheckResponse(["action": ""]).action == .unknown)
        let mistyped = try makeAttributesCheckResponse(["action": 42])
        #expect(mistyped.actionString == nil)
        #expect(mistyped.action == .unknown)
    }

    @Test("Numeric fields are dropped when the server sends them as strings")
    func numericFieldTypes() throws {
        let valid = try makeAttributesCheckResponse(["action": "BUMP", "ver": 12, "t": 500])
        #expect(valid.version?.int64Value == 12)
        #expect(valid.time?.int64Value == 500)

        let mistyped = try makeAttributesCheckResponse(["action": "BUMP", "ver": "12", "t": "500"])
        #expect(mistyped.version == nil)
        #expect(mistyped.time == nil)
    }

    @Test("An unusable project key comes back nil so that no migration fires")
    func projectKey() throws {
        #expect(try makeAttributesCheckResponse(["project_key": "project_12345678"]).projectKey == "project_12345678")
        #expect(try makeAttributesCheckResponse(["project_key": ""]).projectKey == nil)
        #expect(try makeAttributesCheckResponse(["project_key": 1234]).projectKey == nil)
        #expect(try makeAttributesCheckResponse([:]).projectKey == nil)
    }

    @Test("A response that references no query is rejected")
    func missingReference() {
        let withoutIdentifier: BAWSResponseAttributesCheck? = BAWSResponseAttributesCheck(
            response: ["action": "OK"]
        )
        #expect(withoutIdentifier == nil)

        let emptyIdentifier: BAWSResponseAttributesCheck? = BAWSResponseAttributesCheck(
            response: ["id": "", "action": "OK"]
        )
        #expect(emptyIdentifier == nil)

        let empty: BAWSResponseAttributesCheck? = BAWSResponseAttributesCheck(response: [:])
        #expect(empty == nil)
    }
}

@Suite("Attributes send response")
struct AttributesResponseTests {
    @Test("A well formed answer carries the transaction and its version")
    func validAnswer() throws {
        let response = try makeAttributesResponse(["trid": "transaction-id", "ver": 3])
        #expect(response.transactionID == "transaction-id")
        #expect(response.version?.int64Value == 3)
    }

    @Test("A half typed answer is dropped as a whole")
    func typeSanityIsCoupled() throws {
        let mistypedVersion = try makeAttributesResponse(["trid": "transaction-id", "ver": "3"])
        #expect(mistypedVersion.transactionID == nil)
        #expect(mistypedVersion.version == nil)

        let mistypedTransaction = try makeAttributesResponse(["trid": 42, "ver": 3])
        #expect(mistypedTransaction.transactionID == nil)
        #expect(mistypedTransaction.version == nil)
    }

    @Test("An unusable project key comes back nil")
    func projectKey() throws {
        #expect(try makeAttributesResponse(["project_key": "project_12345678"]).projectKey == "project_12345678")
        #expect(try makeAttributesResponse(["project_key": ""]).projectKey == nil)
    }

    @Test("A response that references no query is rejected")
    func missingReference() {
        let withoutIdentifier: BAWSResponseAttributes? = BAWSResponseAttributes(
            response: ["trid": "transaction-id", "ver": 3]
        )
        #expect(withoutIdentifier == nil)
    }
}
