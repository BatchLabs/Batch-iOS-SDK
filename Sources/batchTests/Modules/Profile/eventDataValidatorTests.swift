//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

@testable import Batch
import Batch.Batch_Private
import XCTest

final class eventDataValidatorTests: XCTestCase {
    func testEventNameValidity() throws {
        let invalidEventNames = [
            "invalid event name",
            "invalid-event-name",
            "invalid_event_name@",
            "invalid_event_name\n",
        ]
        for name in invalidEventNames {
            XCTAssertThrowsError(try BAProfileCenter().trackPublicEvent(name: name, attributes: nil))
        }

        XCTAssertNoThrow(try BAProfileCenter().trackPublicEvent(name: "valid_event_name", attributes: nil))
    }

    func testLabel() throws {
        let longLabel = String(repeating: "a_way_too_long_label", count: 20)
        expectEventValidationError("$label: cannot be longer than 200 characters", attributes: BatchEventAttributes { a in
            a.put(longLabel, forKey: "$label")
        })

        expectEventValidationError("$label: cannot be empty or only made of whitespace", attributes: BatchEventAttributes { a in
            a.put("", forKey: "$label")
        })

        expectEventValidationError("$label: cannot be multiline", attributes: BatchEventAttributes { a in
            a.put("with_multi_\n_line", forKey: "$label")
        })

        expectEventValidationSuccess(attributes: BatchEventAttributes { a in
            a.put("a_valid_label", forKey: "$label")
        })
    }

    func testTagsAttribute() throws {
        expectEventValidationError("$tags: must not contain more than 10 values", attributes: BatchEventAttributes { a in
            let tags = (0 ... 10).map { _ in "tag_$i" }
            a.put(tags, forKey: "$tags")
        })

        expectEventValidationError("$tags[2]: tag cannot be empty or made of whitespace", attributes: BatchEventAttributes { a in
            a.put(["tag_0", "tag_1", ""], forKey: "$tags")
        })

        expectEventValidationError("$tags[1]: tag cannot be longer than 64 characters", attributes: BatchEventAttributes { a in
            a.put(["tag_0", String(repeating: "tag_", count: 20)], forKey: "$tags")
        })

        expectEventValidationError("$tags[2]: tag cannot be multiline", attributes: BatchEventAttributes { a in
            a.put(["tag_0", "tag_1", "tag_\n_2"], forKey: "$tags")
        })

        expectEventValidationSuccess(attributes: BatchEventAttributes { a in
            a.put(["tag_0", "tag_1", "tag_2"], forKey: "$tags")
        })
    }

    func testStringAttribute() throws {
        expectEventValidationError("string_attr: string attribute cannot be longer than 200 characters", attributes: BatchEventAttributes { a in
            a.put(String(repeating: "too_long_", count: 100), forKey: "string_attr")
        })

        expectEventValidationError("string_attr: string attribute cannot be empty or made of whitespace", attributes: BatchEventAttributes { a in
            a.put("", forKey: "string_attr")
        })

        expectEventValidationError("string_attr: string attribute cannot be multiline", attributes: BatchEventAttributes { a in
            a.put("with_multi_\n_line", forKey: "string_attr")
        })

        expectEventValidationSuccess(attributes: BatchEventAttributes { a in
            a.put("a_valid_string", forKey: "string_attr")
        })
    }

    func testURLAttribute() throws {
        expectEventValidationError("url_attr: URL attributes cannot be longer than 2048 characters", attributes: BatchEventAttributes { a in
            a.put(URL(string: "https://batch.com/home?id=" + String(repeating: "too_long", count: 1000))!, forKey: "url_attr")
        })

        expectEventValidationError("url_attr: URL attributes must follow the format 'scheme://[authority][path][?query][#fragment]'", attributes: BatchEventAttributes { a in
            a.put(URL(string: "batch.com")!, forKey: "url_attr")
        })

        expectEventValidationSuccess(attributes: BatchEventAttributes { a in
            a.put(URL(string: "https://batch.com/home?id=123")!, forKey: "string_attr")
        })
    }

    func testObjectAttribute() throws {
        let errors = BATEventAttributesValidator(eventAttributes: BatchEventAttributes { a in
            a.put(BatchEventAttributes { a in
                a.put("a_valid_label", forKey: "$label")
                a.put(["tag_0", "tag_1", "tag_2"], forKey: "$tags")
                a.put(BatchEventAttributes { a in
                    a.put(BatchEventAttributes { a in
                        a.put(BatchEventAttributes { _ in }, forKey: "sub_obj_3")
                    },
                    forKey: "sub_obj_2")
                }, forKey: "sub_obj_1")
            }, forKey: "obj_attr")
        }).computeValidationErrors()
        XCTAssertEqual(errors[0], "obj_attr.$label: Labels are not allowed in sub-objects")
        XCTAssertEqual(errors[1], "obj_attr.$tags: Tags are not allowed in sub-objects")
        XCTAssertEqual(errors[2], "obj_attr.sub_obj_1.sub_obj_2.sub_obj_3: Object attributes cannot be nested in more than three levels")

        expectEventValidationError("<attributes root>: objects cannot hold more than 20 attributes", attributes: BatchEventAttributes { a in
            for i in 0 ... 20 {
                a.put("val", forKey: "attr_\(i)")
            }
        })

        expectEventValidationSuccess(attributes: BatchEventAttributes { a in
            a.put(BatchEventAttributes { a in
                a.put("car_brand", forKey: "brand")
                a.put(2024, forKey: "year")
                a.put(false, forKey: "4x4")
                a.put(URL(string: "https://batch.com/")!, forKey: "model_url")
                a.put(BatchEventAttributes { a in
                    a.put("manu", forKey: "manufacturer")
                    a.put(6, forKey: "cylinders")
                    a.put(3.5, forKey: "cylinder_capacity")
                    a.put(Date(timeIntervalSince1970: 1_596_975_143), forKey: "manufacturing_date")
                }, forKey: "engine")
            }, forKey: "my_car")
            a.put("a_test_string", forKey: "string_attr")
            a.put(13, forKey: "int_attr")
            a.put(13.4567, forKey: "double_attr")
            a.put(Date(timeIntervalSince1970: 1_596_975_143), forKey: "date_attr")
            a.put(URL(string: "https://batch.com/")!, forKey: "url_attr")
            a.put(["A", "B", "C"], forKey: "string_list")
            a.put([
                BatchEventAttributes { a in
                    a.put("car_brand", forKey: "brand")
                    a.put(2024, forKey: "year")
                    a.put(false, forKey: "4x4")
                    a.put(URL(string: "https://batch.com/")!, forKey: "model_url")
                    a.put(BatchEventAttributes { a in
                        a.put("manu", forKey: "manufacturer")
                        a.put(6, forKey: "cylinders")
                        a.put(3.5, forKey: "cylinder_capacity")
                        a.put(Date(timeIntervalSince1970: 1_596_975_143), forKey: "manufacturing_date")
                    }, forKey: "engine")
                },
                BatchEventAttributes { a in
                    a.put("car_brand", forKey: "brand")
                    a.put(2024, forKey: "year")
                    a.put(false, forKey: "4x4")
                    a.put(URL(string: "https://batch.com/")!, forKey: "model_url")
                    a.put(BatchEventAttributes { a in
                        a.put("manu", forKey: "manufacturer")
                        a.put(6, forKey: "cylinders")
                        a.put(3.5, forKey: "cylinder_capacity")
                        a.put(Date(timeIntervalSince1970: 1_596_975_143), forKey: "manufacturing_date")
                    }, forKey: "engine")
                },
            ], forKey: "list_items")
            a.put("test_label", forKey: "$label")
            a.put(["tagA", "tagB", "tagC", "tagC"], forKey: "$tags")
        })
    }

    func testStringArrayAttribute() throws {
        expectEventValidationError("string_array_attr[2]: string attribute cannot be longer than 200 characters", attributes: BatchEventAttributes { a in
            a.put(["a", "b", String(repeating: "too_long", count: 40)], forKey: "string_array_attr")
        })

        expectEventValidationError("string_array_attr[1]: string attribute cannot be empty or made of whitespace", attributes: BatchEventAttributes { a in
            a.put(["a", "", "c"], forKey: "string_array_attr")
        })

        expectEventValidationError("string_array_attr[1]: string attribute cannot be multiline", attributes: BatchEventAttributes { a in
            a.put(["a", "with\nlinebreak", "c"], forKey: "string_array_attr")
        })

        expectEventValidationError("list_attr: array attributes cannot have more than 25 elements", attributes: BatchEventAttributes { a in
            let array = (0 ... 25).map { _ in "val_$i" }
            a.put(array, forKey: "list_attr")
        })

        expectEventValidationSuccess(attributes: BatchEventAttributes { a in
            a.put(["a", "b", "c"], forKey: "string_array_attr")
        })
    }

    func expectEventValidationSuccess(attributes: BatchEventAttributes, file: StaticString = #filePath, line: UInt = #line) {
        let errors = BATEventAttributesValidator(eventAttributes: attributes).computeValidationErrors()
        if !errors.isEmpty {
            print("Expected no error, got: \(errors)")
        }
        XCTAssertTrue(errors.isEmpty, file: file, line: line)
    }

    func expectEventValidationError(_ error: String, attributes: BatchEventAttributes, file: StaticString = #filePath, line: UInt = #line) {
        let errors = BATEventAttributesValidator(eventAttributes: attributes).computeValidationErrors()
        let foundError = errors.contains { $0.lowercased() == error.lowercased() }
        if !foundError {
            print("Expected '\(error)', Got: \(errors)")
        }
        XCTAssertTrue(foundError, file: file, line: line)
    }
}
