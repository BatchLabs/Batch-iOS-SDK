//  Copyright © Batch.com. All rights reserved.

import Batch.Batch_Private
import Foundation
import Testing

@testable import Batch

// Raw JSON fixtures lock the CEP wire keys, discriminators, and compatibility behavior.
private enum CEPFixture {
    static func modalJSON(minMLvl: Int = 30) -> String {
        """
        {
          "minMLvl": \(minMLvl),
          "format": "modal",
          "position": "center",
          "trackingId": "tracking-identifier",
          "eventData": { "campaign_token": "cep-wire-format" },
          "root": {
            "backgroundColor": ["#FEFEFEFF", "#202020AD"],
            "margin": [1, 2, 3, 4],
            "radius": [5, 6, 7, 8],
            "borderWidth": 2,
            "borderColor": ["#0F0F0F2E", "#1F1F1F2E"],
            "children": [
              {
                "id": "IMG",
                "type": "image",
                "aspect": "fill",
                "margin": [10, 11, 12, 13],
                "height": "150px",
                "radius": [14, 15, 16, 17]
              },
              {
                "id": "TXT",
                "type": "text",
                "margin": [20, 8, 0, 8],
                "textAlign": "center",
                "fontSize": 22,
                "color": ["#383838FF", "#EFEFEFFF"],
                "maxLines": 3,
                "fontDecoration": ["bold", "italic"]
              },
              {
                "type": "divider",
                "color": ["#CCCCCCFF", "#333333FF"],
                "thickness": 2,
                "margin": [4, 5, 6, 7],
                "width": "50%",
                "align": "left"
              },
              {
                "type": "spacer",
                "height": "24px"
              },
              {
                "type": "columns",
                "ratios": [50, 50],
                "margin": [16, 8, 8, 8],
                "spacing": 8,
                "contentAlign": "bottom",
                "children": [
                  {
                    "id": "BTN",
                    "type": "button",
                    "margin": [0, 1, 2, 3],
                    "padding": [10, 8, 10, 8],
                    "width": "100%",
                    "align": "right",
                    "backgroundColor": ["#0968ACFF", "#0968ACFF"],
                    "radius": [8, 8, 8, 8],
                    "borderWidth": 1,
                    "borderColor": ["#000000FF", "#010101FF"],
                    "textColor": ["#FFFFFFFF", "#FEFEFEFF"],
                    "textAlign": "center",
                    "fontSize": 14,
                    "maxLines": 1,
                    "fontDecoration": ["underline"]
                  },
                  {
                    "id": "BTN_MINIMAL",
                    "type": "button",
                    "backgroundColor": ["#00000000", "#00000000"],
                    "textColor": ["#707070FF", "#EFEFEFFF"],
                    "fontSize": 12
                  }
                ]
              }
            ]
          },
          "closeOptions": {
            "auto": { "delay": 5, "color": ["#FFFFFFFF", "#000000FF"] },
            "button": { "color": ["#707070FF", "#EFEFEFFF"], "backgroundColor": ["#00000000", "#11111100"] }
          },
          "texts": { "IMG": "an image", "TXT": "a title", "BTN": "Okay" },
          "urls": { "IMG": "https://batch.com/image.png" },
          "actions": {
            "BTN": { "action": "batch.deeplink", "params": { "l": "https://batch.com", "li": true } },
            "BTN_MINIMAL": { "action": "batch.dismiss" }
          }
        }
        """
    }

    static let webviewJSON = """
        {
          "minMLvl": 30,
          "format": "webview",
          "root": {
            "children": [
              {
                "id": "WEB",
                "type": "webview",
                "inAppDeeplinks": true,
                "devMode": false,
                "timeout": 12.5
              }
            ]
          },
          "closeOptions": {},
          "urls": { "WEB": "https://batch.com/webview.html" }
        }
        """

    // The bare minimum the model accepts *and* the builders can still render: a lone spacer carries
    // only its own mandatory `height`, so every optional envelope and root key below is absent.
    static func minimalJSON(format: String) -> String {
        """
        {
          "minMLvl": 0,
          "format": "\(format)",
          "root": { "children": [{ "type": "spacer", "height": "24px" }] },
          "closeOptions": {}
        }
        """
    }

    static func decode(_ json: String) throws -> InAppMessage {
        try JSONDecoder().decode(InAppMessage.self, from: Data(json.utf8))
    }

    enum FixtureError: Error {
        case gzipFailed
    }

    static func ld2String(_ json: String) throws -> String {
        guard let gzipped = BATGZIP.data(byGzipping: Data(json.utf8)) else {
            throw FixtureError.gzipFailed
        }
        return String(decoding: BATBase91J().encode(gzipped), as: UTF8.self)
    }

    static func pushPayload(ld: [String: Any]? = nil, ld2: Any? = nil) -> [String: Any] {
        var batchPayload: [String: Any] = [:]
        if let ld {
            batchPayload["ld"] = ld
        }
        if let ld2 {
            batchPayload["ld2"] = ld2
        }
        return ["com.batch": batchPayload]
    }

    static let mepLanding: [String: Any] = ["id": "mep-identifier", "kind": "universal"]
}

@Suite("CEP in-app wire format")
struct InAppMessageWireFormatTests {
    // MARK: - Envelope

    @Suite("Envelope")
    struct Envelope {
        @Test func keys() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())

            #expect(message.format == .modal)
            #expect(message.minMLvl == 30)
            #expect(message.position == .center)
            #expect(message.trackingId == "tracking-identifier")
            #expect(message.eventData == ["campaign_token": "cep-wire-format"])
            #expect(message.texts == ["IMG": "an image", "TXT": "a title", "BTN": "Okay"])
            #expect(message.urls == ["IMG": "https://batch.com/image.png"])
        }

        @Test func actions() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())
            let action = try #require(message.actions?["BTN"])

            #expect(action.action == "batch.deeplink")
            #expect(action.params?["l"] == AnyCodable("https://batch.com"))
            #expect(action.params?["li"] == AnyCodable(true))
        }

        @Test func actionWithoutParams() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())
            let action = try #require(message.actions?["BTN_MINIMAL"])

            #expect(action.action == "batch.dismiss")
            #expect(action.params == nil)
        }

        @Test func closeOptions() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())

            let auto = try #require(message.closeOptions.auto)
            #expect(auto.delay == 5)
            #expect(auto.color == ["#FFFFFFFF", "#000000FF"])

            let button = try #require(message.closeOptions.button)
            #expect(button.color == ["#707070FF", "#EFEFEFFF"])
            #expect(button.backgroundColor == ["#00000000", "#11111100"])
        }

        // Everything but `minMLvl`, `format`, `root` and `closeOptions` is optional on the wire, but
        // an absent key is not a nil the renderer copes with: `InAppMessageBuilder` decides what to
        // draw in its place, and that decision is the contract.
        @Test func optionalKeysAbsent() throws {
            // A modal has nowhere to be laid out without `position`, so the whole message is refused
            // instead of being guessed into place.
            let modal = try CEPFixture.decode(CEPFixture.minimalJSON(format: "modal"))
            #expect(throws: (any Error).self) {
                try InAppMessageBuilder.configuration(for: modal, message: BAMSGCEPMessage())
            }

            // A webview always covers the screen: there the missing position is defaulted instead,
            // and a close cross is injected, otherwise the message could never be dismissed.
            let webview = try CEPFixture.decode(CEPFixture.minimalJSON(format: "webview"))
            let configuration = try InAppMessageBuilder.configuration(for: webview, message: BAMSGCEPMessage())

            #expect(configuration.placement.position == .top)
            #expect(configuration.closeConfiguration.cross != nil)
            // No `closeOptions.auto`: nothing dismisses the message on its own.
            #expect(configuration.closeConfiguration.delay == nil)
            // No `texts`, `urls` nor `actions`: the child is still built, off the empty lookups the
            // builder substitutes for them.
            #expect(configuration.builder.viewsBuilder.count == 1)
        }

        @Test func minMLvlIsMandatory() throws {
            let withoutGate = """
                {
                  "format": "modal",
                  "root": { "children": [] },
                  "closeOptions": {}
                }
                """

            #expect(throws: (any Error).self) {
                try CEPFixture.decode(withoutGate)
            }
        }

        @Test func formats() throws {
            func format(_ wireValue: String) throws -> InAppFormat {
                try CEPFixture.decode(
                    """
                    {
                      "minMLvl": 0,
                      "format": "\(wireValue)",
                      "root": { "children": [] },
                      "closeOptions": {}
                    }
                    """
                )
                .format
            }

            #expect(try format("modal") == .modal)
            #expect(try format("fullscreen") == .fullscreen)
            #expect(try format("webview") == .webview)
        }

        @Test func unknownFormatIsRejected() throws {
            let json = """
                {
                  "minMLvl": 0,
                  "format": "carousel",
                  "root": { "children": [] },
                  "closeOptions": {}
                }
                """

            #expect(throws: (any Error).self) {
                try CEPFixture.decode(json)
            }
        }
    }

    // MARK: - Root container

    @Suite("Root container")
    struct Root {
        @Test func keys() throws {
            let root = try CEPFixture.decode(CEPFixture.modalJSON()).root

            #expect(root.backgroundColor == ["#FEFEFEFF", "#202020AD"])
            #expect(root.margin == [1, 2, 3, 4])
            #expect(root.radius == [5, 6, 7, 8])
            #expect(root.borderWidth == 2)
            #expect(root.borderColor == ["#0F0F0F2E", "#1F1F1F2E"])
            #expect(root.children.count == 5)
        }

        // An absent styling key is not a nil the renderer has to cope with either: it decides what
        // the container is drawn with. A root that styles nothing must still come out opaque (a
        // transparent one would make the whole message invisible), square, borderless, edge to edge.
        @Test func optionalKeysAbsent() throws {
            let message = try CEPFixture.decode(CEPFixture.minimalJSON(format: "modal"))
            let style = try InAppMessageBuilder.configurationStyle(inAppMessage: message)
            let placement = try InAppMessageBuilder.rootContainer(inAppMessage: message).placement

            #expect(placement.margins == UIEdgeInsets.zero)
            #expect(style.radius == [0, 0, 0, 0])
            #expect(style.borderWidth == 0)
            #expect(style.backgroundColor?.cgColor.alpha == 1)
            #expect(style.borderColor?.cgColor.alpha == 0)
        }
    }

    // MARK: - Components

    @Suite("Components")
    struct Components {
        @Test func image() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())
            let image = try #require(message.root.children[0].component as? InAppImage)

            #expect(image.id == "IMG")
            #expect(image.type == .image)
            #expect(image.aspect == .fill)
            #expect(image.margin == [10, 11, 12, 13])
            #expect(image.height == "150px")
            #expect(image.radius == [14, 15, 16, 17])
        }

        @Test func label() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())
            let label = try #require(message.root.children[1].component as? InAppLabel)

            #expect(label.id == "TXT")
            #expect(label.type == .text)
            #expect(label.margin == [20, 8, 0, 8])
            #expect(label.textAlign == .center)
            #expect(label.fontSize == 22)
            #expect(label.color == ["#383838FF", "#EFEFEFFF"])
            #expect(label.maxLines == 3)
            #expect(label.fontDecoration == [.bold, .italic])
        }

        @Test func divider() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())
            let divider = try #require(message.root.children[2].component as? InAppDivider)

            #expect(divider.type == .divider)
            #expect(divider.color == ["#CCCCCCFF", "#333333FF"])
            #expect(divider.thickness == 2)
            #expect(divider.margin == [4, 5, 6, 7])
            #expect(divider.width == "50%")
            #expect(divider.align == .left)
        }

        @Test func spacer() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())
            let spacer = try #require(message.root.children[3].component as? InAppSpacer)

            #expect(spacer.type == .spacer)
            #expect(spacer.height == "24px")
        }

        @Test func columns() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())
            let columns = try #require(message.root.children[4].component as? InAppColumns)

            #expect(columns.type == .columns)
            #expect(columns.ratios == [50, 50])
            #expect(columns.margin == [16, 8, 8, 8])
            #expect(columns.spacing == 8)
            #expect(columns.contentAlign == .bottom)
            #expect(columns.children.count == 2)
        }

        @Test func columnRatiosAcceptFloats() throws {
            let json = """
                {
                  "minMLvl": 0,
                  "format": "modal",
                  "root": {
                    "children": [{ "type": "columns", "children": [], "ratios": [33.0, 67.0] }]
                  },
                  "closeOptions": {}
                }
                """

            let message = try CEPFixture.decode(json)
            let columns = try #require(message.root.children[0].component as? InAppColumns)

            #expect(columns.ratios == [33, 67])
        }

        @Test func button() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())
            let columns = try #require(message.root.children[4].component as? InAppColumns)
            let button = try #require(columns.children[0]?.component as? InAppButton)

            #expect(button.id == "BTN")
            #expect(button.type == .button)
            #expect(button.margin == [0, 1, 2, 3])
            #expect(button.padding == [10, 8, 10, 8])
            #expect(button.width == "100%")
            #expect(button.align == .right)
            #expect(button.backgroundColor == ["#0968ACFF", "#0968ACFF"])
            #expect(button.radius == [8, 8, 8, 8])
            #expect(button.borderWidth == 1)
            #expect(button.borderColor == ["#000000FF", "#010101FF"])
            #expect(button.textColor == ["#FFFFFFFF", "#FEFEFEFF"])
            #expect(button.textAlign == .center)
            #expect(button.fontSize == 14)
            #expect(button.maxLines == 1)
            #expect(button.fontDecoration == [.underline])
        }

        @Test func buttonOptionalKeysAbsent() throws {
            let message = try CEPFixture.decode(CEPFixture.modalJSON())
            let columns = try #require(message.root.children[4].component as? InAppColumns)
            let button = try #require(columns.children[1]?.component as? InAppButton)

            #expect(button.id == "BTN_MINIMAL")
            #expect(button.backgroundColor == ["#00000000", "#00000000"])
            #expect(button.textColor == ["#707070FF", "#EFEFEFFF"])
            #expect(button.fontSize == 12)
            #expect(button.margin == nil)
            #expect(button.padding == nil)
            #expect(button.width == nil)
            #expect(button.align == nil)
            #expect(button.radius == nil)
            #expect(button.borderWidth == nil)
            #expect(button.borderColor == nil)
            #expect(button.textAlign == nil)
            #expect(button.maxLines == nil)
            #expect(button.fontDecoration == nil)
        }

        @Test func webview() throws {
            let message = try CEPFixture.decode(CEPFixture.webviewJSON)
            let webview = try #require(message.root.children[0].component as? InAppWebview)

            #expect(message.format == .webview)
            #expect(webview.id == "WEB")
            #expect(webview.type == .webview)
            #expect(webview.inAppDeeplinks)
            #expect(!webview.devMode)
            #expect(webview.timeout == 12.5)
        }

        @Test func unknownComponentTypeIsRejected() throws {
            let json = """
                {
                  "minMLvl": 0,
                  "format": "modal",
                  "root": { "children": [{ "id": "X", "type": "carousel" }] },
                  "closeOptions": {}
                }
                """

            #expect(throws: (any Error).self) {
                try CEPFixture.decode(json)
            }
        }
    }

    // MARK: - Forward compatibility

    @Suite("Unknown fields")
    struct UnknownFields {
        @Test func areIgnored() throws {
            let json = """
                {
                  "minMLvl": 0,
                  "format": "modal",
                  "futureEnvelopeKey": { "nested": [1, 2, 3] },
                  "root": {
                    "futureRootKey": "whatever",
                    "children": [
                      {
                        "id": "TXT",
                        "type": "text",
                        "fontSize": 18,
                        "color": ["#000000FF", "#FFFFFFFF"],
                        "futureComponentKey": true
                      }
                    ]
                  },
                  "closeOptions": { "futureCloseKey": 42 }
                }
                """

            let message = try CEPFixture.decode(json)
            let label = try #require(message.root.children[0].component as? InAppLabel)

            #expect(message.format == .modal)
            #expect(label.id == "TXT")
            #expect(label.fontSize == 18)
        }
    }

    // MARK: - Transport

    @Suite("Transport")
    struct Transport {
        // `ld2` is a Base91J-encoded gzipped JSON *string*. Anything else is not a CEP message.
        // Full round trip, exactly as `InAppViewControllerProvider` does it.
        @Test func ld2StringDecodesIntoTheModel() throws {
            let ld2 = try CEPFixture.ld2String(CEPFixture.modalJSON())
            let payload = CEPFixture.pushPayload(ld2: ld2)
            let message = try #require(BatchMessaging.message(fromPushPayload: payload))

            #expect(message.isCEPMessage)
            #expect(message.devTrackingIdentifier == "tracking-identifier")

            let jsonData = try JSONSerialization.data(withJSONObject: message.messagePayload)
            let inAppMessage = try JSONDecoder().decode(InAppMessage.self, from: jsonData)

            #expect(inAppMessage.format == .modal)
            #expect(inAppMessage.root.children.count == 5)
            #expect(inAppMessage.texts?["TXT"] == "a title")
        }

        @Test func ld2DictionaryIsNotCEP() throws {
            let payload = CEPFixture.pushPayload(ld2: ["format": "modal", "minMLvl": 0])

            #expect(BatchMessaging.message(fromPushPayload: payload) == nil)
        }

        @Test func ld2DictionaryFallsBackToMEP() throws {
            let payload = CEPFixture.pushPayload(ld: CEPFixture.mepLanding, ld2: ["format": "modal", "minMLvl": 0])
            let message = try #require(BatchMessaging.message(fromPushPayload: payload))

            #expect(!message.isCEPMessage)
            #expect(message.messageIdentifier == "mep-identifier")
        }

        @Test func ldDictionaryIsMEP() throws {
            let payload = CEPFixture.pushPayload(ld: CEPFixture.mepLanding)
            let message = try #require(BatchMessaging.message(fromPushPayload: payload))

            #expect(!message.isCEPMessage)
            #expect(message.messageIdentifier == "mep-identifier")
        }

        @Test func ld2StringTakesPrecedenceOverLd() throws {
            let ld2 = try CEPFixture.ld2String(CEPFixture.modalJSON())
            let payload = CEPFixture.pushPayload(ld: CEPFixture.mepLanding, ld2: ld2)
            let message = try #require(BatchMessaging.message(fromPushPayload: payload))

            #expect(message.isCEPMessage)
            #expect(message.messagePayload["format"] as? String == "modal")
        }

        @Test func corruptedLd2IsRejected() throws {
            let payload = CEPFixture.pushPayload(ld: CEPFixture.mepLanding, ld2: "not base91")

            #expect(BatchMessaging.message(fromPushPayload: payload) == nil)
        }

        @Test func missingBothIsRejected() throws {
            #expect(BatchMessaging.message(fromPushPayload: CEPFixture.pushPayload()) == nil)
        }
    }

    // MARK: - Messaging API level gate

    @Suite("minMLvl gate")
    struct MinimumMessagingLevel {
        // The parsed message must keep a pointer back to its raw `BatchMessage`: analytics and action
        // handlers read the campaign identifiers off `sourceMessage`, so losing it breaks tracking
        // without breaking rendering.
        @Test func compliantMessageIsParsed() throws {
            let ld2 = try CEPFixture.ld2String(CEPFixture.modalJSON(minMLvl: 1))
            let payload = CEPFixture.pushPayload(ld2: ld2)
            let rawMessage = try #require(BatchMessaging.message(fromPushPayload: payload))

            let parsed = try #require(BAMSGPayloadParser.message(forCEPRawMessage: rawMessage, bailIfNotAlert: false))
            #expect(parsed.sourceMessage === rawMessage)
        }

        @Test func tooRecentMessageIsDropped() throws {
            let ld2 = try CEPFixture.ld2String(CEPFixture.modalJSON(minMLvl: 9999))
            let payload = CEPFixture.pushPayload(ld2: ld2)
            let rawMessage = try #require(BatchMessaging.message(fromPushPayload: payload))

            #expect(BAMSGPayloadParser.message(forCEPRawMessage: rawMessage, bailIfNotAlert: false) == nil)
        }

        // The two generations gate on two different keys — `minapi` for MEP, `minMLvl` for CEP. Wiring
        // the CEP parser to the MEP key would silently drop every CEP landing whose campaign still
        // carries a `minapi`, and let a genuinely too-recent one through.
        @Test func theMEPGateKeyIsIgnored() throws {
            let json = """
                {
                  "minMLvl": 1,
                  "minapi": 9999,
                  "format": "modal",
                  "root": { "children": [{ "type": "spacer", "height": "24px" }] }
                }
                """
            let payload = CEPFixture.pushPayload(ld2: try CEPFixture.ld2String(json))
            let rawMessage = try #require(BatchMessaging.message(fromPushPayload: payload))

            #expect(BAMSGPayloadParser.message(forCEPRawMessage: rawMessage, bailIfNotAlert: false) != nil)
        }
    }
}
