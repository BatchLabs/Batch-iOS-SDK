//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import XCTest

@testable import Batch

final class eventDataSerializerTests: XCTestCase {
    func testAttributesSerialization() throws {
        // Tags are not tested here: the SDK can randomize the order, making it hard to compare in bulk

        let eventAttributes = BatchEventAttributes { a in
            a.put("test_label", forKey: "$label")
            a.put(self.makeCar(brand: "toyota"), forKey: "my_car")
            a.put("a_test_string", forKey: "string_attr")
            a.put(13, forKey: "int_attr")
            a.put(13.4567, forKey: "double_attr")
            a.put(Date(timeIntervalSince1970: 1_596_975_143), forKey: "date_attr")
            a.put(URL(string: "https://batch.com/")!, forKey: "url_attr")
            a.put(["A", "B", "C"], forKey: "string_list")
            a.put([self.makeCar(brand: "peugeot"), self.makeCar(brand: "audi")], forKey: "list_items")
        }

        let json = try BATEventAttributesSerializer.serialize(eventAttributes: eventAttributes)
        let expected: [AnyHashable: Any] = [
            "label": "test_label",

            "attributes": [
                "string_attr.s": "a_test_string",
                "int_attr.i": 13,
                "double_attr.f": 13.4567,
                "date_attr.t": 1_596_975_143_000,
                "url_attr.u": "https://batch.com/",
                "string_list.a": ["A", "B", "C"],
                "my_car.o": makeExpectedCar(brand: "toyota"),
                "list_items.a": [makeExpectedCar(brand: "peugeot"), makeExpectedCar(brand: "audi")],
            ],
        ]

        XCTAssertEqual(expected as NSDictionary, json as NSDictionary)
    }

    func testTagsSerialization() throws {
        let eventAttributes = BatchEventAttributes { a in
            a.put(["tagA", "tagB", "tagC", "tagC"], forKey: "$tags")
        }

        let json = try BATEventAttributesSerializer.serialize(eventAttributes: eventAttributes)

        guard let tags = json["tags"] as? [String] else {
            XCTFail("tags is missing from serialized attributes or not a string array")
            return
        }
        XCTAssertEqual(3, tags.count)
        XCTAssertTrue(tags.contains("taga"))
        XCTAssertTrue(tags.contains("tagb"))
        XCTAssertTrue(tags.contains("tagc"))
    }

    func makeCar(brand: String) -> BatchEventAttributes {
        return BatchEventAttributes { a in
            a.put(brand, forKey: "brand")
            a.put(2024, forKey: "year")
            a.put(false, forKey: "4x4")
            a.put(URL(string: "https://batch.com/")!, forKey: "model_url")
            a.put(
                BatchEventAttributes { a in
                    a.put("manu", forKey: "manufacturer")
                    a.put(6, forKey: "cylinders")
                    a.put(3.5, forKey: "cylinder_capacity")
                    a.put(Date(timeIntervalSince1970: 1_596_975_143), forKey: "manufacturing_date")
                },
                forKey: "engine"
            )
        }
    }

    func makeExpectedCar(brand: String) -> [AnyHashable: Any] {
        return [
            "brand.s": brand,
            "year.i": 2024,
            "model_url.u": "https://batch.com/",
            "4x4.b": false,
            "engine.o": [
                "manufacturer.s": "manu",
                "cylinders.i": 6,
                "cylinder_capacity.f": 3.5,
                "manufacturing_date.t": 1_596_975_143_000,
            ],
        ]
    }
}
