//
//  eventTrackerServiceTests.swift
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import XCTest

class eventTrackerServiceTests: XCTestCase {
    let events: [BAEvent] = [
        eventTrackerServiceTests.makeEvent(id: 1, state: BAEventStateNew),
        eventTrackerServiceTests.makeEvent(id: 2, state: BAEventStateOld),
    ]

    static func makeEvent(id: Int, state: BAEventState) -> BAEvent {
        return BAEvent(
            identifier: "\(id)",
            name: "test",
            date: "\(id)234",
            secureDate: "\(id)2345",
            parameters: """
            {"foo": "bar\(id)"}
            """,
            state: state,
            session: "s\(id)",
            andTick: Int64(990 + id)
        )
    }

    static func makeSerializedEvent(id: Int) -> [String: Any] {
        return [
            "id": "\(id)",
            "name": "test",
            "date": "\(id)234",
            "ts": Int64(990 + id),
            "session": "s\(id)",
            "params": ["foo": "bar\(id)"],
            "sDate": "\(id)2345",
        ]
    }

    func testIdentifier() {
        XCTAssertEqual(makeService().requestIdentifier, "track")
    }

    func testShortIdentifier() {
        XCTAssertEqual(makeService().requestShortIdentifier, "tr")
    }

    func testURL() {
        let _ = BACoreCenter.instance().configuration.setDevelopperKey("ABCDEF")
        let url = makeService().requestURL
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("tr"))
        // TODO: better tests with ocmock or DI
    }

    func testQuery() throws {
        for service in [makeServiceWithEvents(), makeServiceWithPromises([BAPromise(), BAPromise()])] {
            let queries = service.queriesToSend
            let query = try XCTUnwrap(queries[0] as? BAWSQueryTracking)

            let serializedQuery = query.objectToSend()
            let serializedEvents = try XCTUnwrap(serializedQuery["evts"] as? [AnyHashable: Any])
            let new = try XCTUnwrap(serializedEvents["new"] as? [[AnyHashable: Any]])
            let old = try XCTUnwrap(serializedEvents["old"] as? [[AnyHashable: Any]])
            XCTAssertEqual(new.count, 1)
            XCTAssertEqual(old.count, 1)

            XCTAssertTrue((new[0] as NSDictionary).isEqual(to: eventTrackerServiceTests.makeSerializedEvent(id: 1)))
            XCTAssertTrue((old[0] as NSDictionary).isEqual(to: eventTrackerServiceTests.makeSerializedEvent(id: 2)))
        }
    }

    // Regression test for a prerelease 1.19.0 crash where objectToSend() crashed when serializing an event with no session
    func testCanSerializeEventWithNoSession() throws {
        let events = [
            BAEvent(
                identifier: "foobar",
                name: "test",
                date: "234",
                secureDate: "2345",
                parameters: """
                {"foo": "bar"}
                """,
                state: BAEventStateOld,
                session: nil,
                andTick: Int64(990)
            ),
        ]
        let service = BAEventTrackerService(events: events as [Any])
        // The bug made "objectToSend" crash: simply calling it was enough to trigger it, no need to test any value
        let queries = service.queriesToSend
        let query = try XCTUnwrap(queries[0] as? BAWSQueryTracking)

        query.objectToSend()
    }

    func testResponse() {
        let service = makeService()
        XCTAssertTrue(
            service.response(for: BAWSQueryTracking(events: []), content: makeBasicQueryResponseDictionary())
                is BAWSResponseTracking)
    }

    func testWebserviceFail() {
        let promises = [BAPromise(), BAPromise()]
        let service = makeServiceWithPromises(promises)
        service.webserviceClient(
            makeQueryClient(service: service), didFailWithError: NSError(domain: "test", code: 1, userInfo: nil)
        )
        XCTAssertTrue(promises[0].status == BAPromiseStatus.rejected)
        XCTAssertTrue(promises[1].status == BAPromiseStatus.rejected)
        // TODO: Test non promise failure
    }

    func testWebserviceSuccess() {
        let promises = [BAPromise(), BAPromise()]
        let service = makeServiceWithPromises(promises)
        service.webserviceClient(
            makeQueryClient(service: service),
            didSucceedWith: [BAWSResponseTracking(response: makeBasicQueryResponseDictionary())]
        )
        XCTAssertTrue(promises[0].status == BAPromiseStatus.resolved)
        XCTAssertTrue(promises[1].status == BAPromiseStatus.resolved)
        // TODO: Test non promise success
    }

    func makeService() -> BAEventTrackerService {
        return BAEventTrackerService(events: [])
    }

    func makeServiceWithEvents() -> BAEventTrackerService {
        return BAEventTrackerService(events: events)
    }

    func makeServiceWithPromises(_ promises: [BAPromise<NSObject>]) -> BAEventTrackerService {
        return BAEventTrackerService(events: events, promises: promises)
    }

    func makeQueryClient(service: BAEventTrackerService) -> BAQueryWebserviceClient {
        return BAQueryWebserviceClient(datasource: service, delegate: service)
    }

    func makePromises() -> [BAPromise<NSObject>] {
        return [
            BAPromise(),
            BAPromise(),
        ]
    }
}
