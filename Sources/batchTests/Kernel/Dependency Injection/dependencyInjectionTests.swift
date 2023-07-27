//
//  dependencyInjectionTests.swift
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import Foundation
import XCTest

class dependencyInjectionTests: XCTestCase {
    func testInstanceInjection() throws {
        let registry = BAInjectionRegistry()

        XCTAssertNil(registry.inject(class: injectionTestClass.self))
        XCTAssertNil(registry.inject(protocol: injectionTestProtocol.self))
        XCTAssertNil(registry.inject(class: injectionOffsetableTestClass.self))

        let classToInject = injectionTestClass()

        let injectable = BAInjectable(instance: classToInject)
        registry.register(injectable: injectable, forClass: injectionTestClass.self)
        registry.register(injectable: injectable, forProtocol: injectionTestProtocol.self)

        let injectedClass = try XCTUnwrap(registry.inject(class: injectionTestClass.self) as? injectionTestClass)
        let injectedProtocol = try XCTUnwrap(
            registry.inject(protocol: injectionTestProtocol.self) as? injectionTestProtocol)

        XCTAssertTrue(injectedClass === classToInject)
        XCTAssertTrue(injectedProtocol === classToInject)
        XCTAssertEqual(1, injectedClass.echo(1))
        XCTAssertEqual(1, injectedProtocol.echo(1))

        XCTAssertNil(registry.inject(class: injectionOffsetableTestClass.self))
    }

    func testNilInstanceInjection() throws {
        let registry = BAInjectionRegistry()

        XCTAssertNil(registry.inject(class: injectionTestClass.self))
        XCTAssertNil(registry.inject(protocol: injectionTestProtocol.self))
        XCTAssertNil(registry.inject(class: injectionOffsetableTestClass.self))

        let injectable = BAInjectable(instance: nil)
        registry.register(injectable: injectable, forClass: injectionTestClass.self)
        registry.register(injectable: injectable, forProtocol: injectionTestProtocol.self)

        XCTAssertNil(registry.inject(class: injectionTestClass.self))
        XCTAssertNil(registry.inject(protocol: injectionTestProtocol.self))
        XCTAssertNil(registry.inject(class: injectionOffsetableTestClass.self))
    }

    func testNilBlockInjection() throws {
        let registry = BAInjectionRegistry()

        XCTAssertNil(registry.inject(class: injectionTestClass.self))
        XCTAssertNil(registry.inject(protocol: injectionTestProtocol.self))
        XCTAssertNil(registry.inject(class: injectionOffsetableTestClass.self))

        let injectable = BAInjectable { () -> Any? in
            return nil
        }
        registry.register(injectable: injectable, forClass: injectionTestClass.self)
        registry.register(injectable: injectable, forProtocol: injectionTestProtocol.self)

        XCTAssertNil(registry.inject(class: injectionTestClass.self))
        XCTAssertNil(registry.inject(protocol: injectionTestProtocol.self))
        XCTAssertNil(registry.inject(class: injectionOffsetableTestClass.self))
    }

    func testInstanceBlockInjection() throws {
        let registry = BAInjectionRegistry()

        XCTAssertNil(registry.inject(class: injectionOffsetableTestClass.self))
        XCTAssertNil(registry.inject(protocol: injectionTestProtocol.self))

        var blockInstantiatorCounter = 1
        let injectable = BAInjectable { () -> Any? in
            return injectionOffsetableTestClass(offset: blockInstantiatorCounter)
        }
        registry.register(injectable: injectable, forClass: injectionOffsetableTestClass.self)
        registry.register(injectable: injectable, forProtocol: injectionTestProtocol.self)

        var injectedClass = try XCTUnwrap(
            registry.inject(class: injectionOffsetableTestClass.self) as? injectionOffsetableTestClass)
        var injectedProtocol = try XCTUnwrap(
            registry.inject(protocol: injectionTestProtocol.self) as? injectionTestProtocol)

        // Echo is offsetted by blockInstantiatorCounter

        XCTAssertEqual(1, injectedClass.echo(0))
        XCTAssertEqual(1, injectedProtocol.echo(0))

        blockInstantiatorCounter = 2

        injectedClass = try XCTUnwrap(
            registry.inject(class: injectionOffsetableTestClass.self) as? injectionOffsetableTestClass)
        injectedProtocol = try XCTUnwrap(
            registry.inject(protocol: injectionTestProtocol.self) as? injectionTestProtocol)
        XCTAssertEqual(2, injectedClass.echo(0))
        XCTAssertEqual(2, injectedProtocol.echo(0))
        blockInstantiatorCounter = 1
        XCTAssertEqual(2, injectedClass.echo(0))
        XCTAssertEqual(2, injectedProtocol.echo(0))
    }

    // This test tests that overlays work, and also tests the lifecycle (memory rentention: releasing the overlay should disable it automatically)
    func testOverlays() throws {
        // Inject a reference class
        let registry = BAInjectionRegistry()

        XCTAssertNil(registry.inject(protocol: injectionTestProtocol.self))
        XCTAssertNil(registry.inject(class: injectionOffsetableTestClass.self))

        let injectable = BAInjectable(instance: injectionOffsetableTestClass(offset: 0))
        registry.register(injectable: injectable, forClass: injectionOffsetableTestClass.self)
        registry.register(injectable: injectable, forProtocol: injectionTestProtocol.self)
        // Also register another class to make sure we don't fuck with it
        registry.register(injectable: BAInjectable(instance: injectionTestClass()), forClass: injectionTestClass.self)

        var injectedClass = injectionOffsetableTestClass(offset: 10)
        var injectedProtocol: injectionTestProtocol = injectionTestClass()
        var injectedUntouchedClass = injectionTestClass()

        func refreshInjections() throws {
            injectedClass = try XCTUnwrap(
                registry.inject(class: injectionOffsetableTestClass.self) as? injectionOffsetableTestClass)
            injectedProtocol = try XCTUnwrap(
                registry.inject(protocol: injectionTestProtocol.self) as? injectionTestProtocol)
            injectedUntouchedClass = try XCTUnwrap(
                registry.inject(class: injectionTestClass.self) as? injectionTestClass)
        }
        try refreshInjections()

        XCTAssertEqual(1, injectedClass.echo(1))
        XCTAssertEqual(1, injectedProtocol.echo(1))
        XCTAssertEqual(1, injectedUntouchedClass.echo(1))

        var overlay: BAOverlayedInjectable?

        // Test the memory lifecycle: releasing the value should
        // An autorelease pool is needed due to ARC's implicit autorelease
        // You can also manually release it.

        autoreleasepool {
            overlay = registry.overlayClass(injectionOffsetableTestClass.self) { (_: Any?) -> Any? in
                return injectionOffsetableTestClassMock(offset: 0)
            }

            try! refreshInjections()

            XCTAssertEqual(90, injectedClass.echo(1))
            XCTAssertEqual(1, injectedProtocol.echo(1))
            XCTAssertEqual(1, injectedUntouchedClass.echo(1))
        }

        // Manual releasing
        overlay = registry.overlayProtocol(injectionTestProtocol.self) { (_: Any?) -> Any? in
            return injectionTestClassMock()
        }

        try refreshInjections()

        XCTAssertEqual(1, injectedClass.echo(1))
        XCTAssertEqual(80, injectedProtocol.echo(1))
        XCTAssertEqual(1, injectedUntouchedClass.echo(1))
        registry.unregisterOverlay(overlay!)

        // "overlay" points to an unregistered overlay
        // Clean it up anywayto make the test cleaner
        overlay = nil
        try refreshInjections()

        XCTAssertEqual(1, injectedClass.echo(1))
        XCTAssertEqual(1, injectedProtocol.echo(1))
        XCTAssertEqual(1, injectedUntouchedClass.echo(1))

        // Test that nil values work
        overlay = registry.overlayClass(injectionOffsetableTestClass.self) { (_: Any?) -> Any? in
            return nil
        }

        XCTAssertNil(registry.inject(class: injectionOffsetableTestClass.self))
        XCTAssertNotNil(registry.inject(protocol: injectionTestProtocol.self))
    }
}

@objc
protocol injectionTestProtocol {
    @objc func echo(_ i: Int) -> Int
}

class injectionTestClass: NSObject, injectionTestProtocol {
    @objc
    func echo(_ i: Int) -> Int {
        return i
    }
}

class injectionOffsetableTestClass: NSObject, injectionTestProtocol {
    let offset: Int

    init(offset: Int) {
        self.offset = offset
        super.init()
    }

    @objc
    func echo(_ i: Int) -> Int {
        return i + offset
    }
}

class injectionTestClassMock: NSObject, injectionTestProtocol {
    @objc
    func echo(_: Int) -> Int {
        return 80
    }
}

class injectionOffsetableTestClassMock: injectionOffsetableTestClass {
    @objc
    override func echo(_: Int) -> Int {
        return 90
    }
}
