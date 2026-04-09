//
//  metricTests.swift
//  batchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Foundation
import Testing

@testable import Batch

struct MetricTests {
    @Test func testToDictionary() throws {
        let counter = BACounter(name: "counter_test_metric", andLabelNamesList: ["label"])
        counter.increment()

        let dict = counter.toDictionary() as NSDictionary

        #expect(dict["name"] as? String == "counter_test_metric")
        #expect(dict["type"] as? String == "counter")

        let values = try #require(dict["values"] as? [NSNumber])
        #expect(values.count == 1)
        #expect(values[0].doubleValue == 1.0)
    }

    @Test func testHasChanged() {
        let counter = BACounter(name: "counter_test_metric")
        #expect(counter.hasChanged() == false)
        counter.increment()
        #expect(counter.hasChanged())
    }

    @Test func testHasChildren() {
        let counter = BACounter(name: "counter_test_metric", andLabelNamesList: ["label"])
        #expect(counter.hasChildren() == false)
        let child = counter.labels(["label"]) as? BACounter
        child?.increment()
        #expect(counter.hasChildren())
    }

    @Test func testCopy() {
        // Non regression test, copyWithZone was not implemented correctly and
        // returned BAMetric instances when copying one of its subclasses
        let metric = BAMetric(name: "counter_test_metric", andLabelNamesList: ["label"])
        let counter = BACounter(name: "counter_test_metric", andLabelNamesList: ["label"])
        let observation = BAObservation(name: "counter_test_metric", andLabelNamesList: ["label"])

        #expect(type(of: metric.copy() as AnyObject) == BAMetric.self)
        #expect(type(of: counter.copy() as AnyObject) == BACounter.self)
        #expect(type(of: observation.copy() as AnyObject) == BAObservation.self)
    }

    @Test func testObservationChildInheritsStartTime() throws {
        let observation = BAObservation(name: "observation_test_metric", andLabelNamesList: ["type"])
        observation.startTimer()
        Thread.sleep(forTimeInterval: 0.01)
        let child = observation.labels(["image"]) as? BAObservation
        child?.observeDuration()

        let values = try #require(child?.values)
        let firstValue = try #require(values.firstObject as? NSNumber)
        #expect(firstValue.doubleValue < 10.0)
    }
}
