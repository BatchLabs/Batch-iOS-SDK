//
//  batchListpTests.swift
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import Batch.Batch_Private
import XCTest

typealias PrimitiveValue = BALPrimitiveValue
typealias VariableValue = BALVariableValue

class batchLispTests: XCTestCase {

    let context = TestsEvaluationContext()

    override func setUp() {
    }

    override func tearDown() {
    }

    //MARK: AST Tests

    func testBasicAST() {
        assert(
            expression: "(= 1 2)",
            parsesTo: [
                MockOperator("="),
                PrimitiveValue(double: 1),
                PrimitiveValue(double: 2),
            ])

        assert(
            expression: "(= true (> 1 2))",
            parsesTo: [
                MockOperator("="),
                PrimitiveValue.init(boolean: true),
                [
                    MockOperator(">"),
                    PrimitiveValue(double: 1),
                    PrimitiveValue(double: 2),
                ] as LiteralSExpression,
            ])

        assert(
            expression: "(= `foo` \"bar\")",
            parsesTo: [
                MockOperator("="),
                VariableValue.variable(withName: "foo"),
                PrimitiveValue(string: "bar")!,
            ])

        assert(
            expression: "(= true \"bar\\n\\t\\r\\\"\\\'\\\\ \")",
            parsesTo: [
                MockOperator("="),
                PrimitiveValue.init(boolean: true),
                PrimitiveValue(string: "bar\n\t\r\"\'\\ ")!,
            ])

        assert(
            expression: "(= true [\"a\" \"b\"])",
            parsesTo: [
                MockOperator("="),
                PrimitiveValue.init(boolean: true),
                PrimitiveValue.init(stringSet: ["a", "b"])!,
            ])

        // Test that a set is a set and not an array
        assert(
            expression: "(= true [\"b\" \"a\" \"b\"])",
            parsesTo: [
                MockOperator("="),
                PrimitiveValue.init(boolean: true),
                PrimitiveValue.init(stringSet: ["a", "b"])!,
            ])
    }

    func testMalformedExpressions() {
        assertParsingError("(= 2 2")
        assertParsingError("= 2 2")
        assertEvaluationError("(2 2)")
        assertEvaluationError("(2)")
    }

    func testVariables() {
        assertTrue("(= `foo` \"bar\")")
        assertTrue("(= `unknown` nil)")
    }

    func testSubexpressions() {
        assertTrue("(= true (= true true))")
        assertFalse("(= true (= true false))")
    }

    //MARK: Operator tests

    func testEqualityOperator() {
        assertTrue("(=)")
        assertTrue("(= 2 2)")
        assertTrue("(= true true)")
        assertTrue("(= \"ok\" \"ok\")")

        assertFalse("(= 2 3)")
        assertFalse("(= true false)")
        assertFalse("(= \"ok\" \"not ok\")")

        // Can't compare values of different type
        assertFalse("(= 2 true)")
    }

    func testIfOperator() {
        assertTrue("(if true true false)")
        assertFalse("(if false true false)")
        assertTrue("(if (= 2 2) true false)")
        assertTrue("(= (if true 2 1) 2)")
        assertTrue("(= (if true \"ok\") \"ok\")")
        assertTrue("(= (if true [\"ok\"]) [\"ok\"])")
        assertTrue("(= nil (if false true))")
        assertTrue("(= nil (if true nil false))")

        assertEvaluationError("(if nil true false true)")
        assertEvaluationError("(if nil)")
        assertEvaluationError("(if)")
        assertEvaluationError("(if 2 true)")
        assertEvaluationError("(if \"ok\" true)")
        assertEvaluationError("(if [\"ok\"] true)")
    }

    func testNotOperator() {
        // Not only works with one boolean
        assertEvaluationError("(not)")
        assertEvaluationError("(not true true)")
        assertEvaluationError("(not 1)")
        assertEvaluationError("(not \"ok\")")

        assertFalse("(not true)")
        assertTrue("(not false)")
    }

    func testAndOperator() {
        assertFalse("(and true false)")
        assertFalse("(and false true)")
        assertTrue("(and true true)")
        assertFalse("(and false false)")

        assertFalse("(and true nil)")
        assertFalse("(and nil true)")

        assertEvaluationError("(and \"bar\" true)")
        assertFalse("(and false \"bar\")")
        assertEvaluationError("(and 2 true)")
        assertFalse("(and false 2)")
    }

    func testOrOperator() {
        assertTrue("(or true false)")
        assertTrue("(or false true)")
        assertTrue("(or true true)")
        assertFalse("(or false false)")

        assertTrue("(or true nil)")
        assertTrue("(or nil true)")
        assertFalse("(or false nil)")
        assertFalse("(or nil false)")

        assertEvaluationError("(or \"bar\" true)")
        assertTrue("(or true \"bar\")")
        assertEvaluationError("(or 2 true)")
        assertTrue("(or true 2)")
    }

    func testNumberComparisonOperators() {
        assertTrue("(> 3 2)")
        assertTrue("(> 3 2 1 0 -1)")
        assertFalse("(> 3 2 1 0 4)")
        assertFalse("(> 2 2)")
        assertFalse("(> 2 2 1)")
        assertFalse("(>= 3 2 1 0 4)")
        assertTrue("(>= 2 2)")
        assertTrue("(>= 2 2 1)")

        assertTrue("(< 2 3)")
        assertTrue("(< 2 3 4 5 6)")
        assertFalse("(< 2 3 4 5 6 1)")
        assertFalse("(< 2 2)")
        assertFalse("(< 2 2 3)")
        assertFalse("(<= 2 3 4 5 6 1)")
        assertTrue("(<= 2 2)")
        assertTrue("(<= 2 2 3)")
    }

    func testSetContains() {
        assertTrue("(contains \"foo\" [\"foo\" \"bar\"])")
        assertTrue("(contains [\"foo\"] [\"foo\" \"bar\"])")
        assertTrue("(contains [\"foo\" \"lorem\"] [\"foo\" \"bar\"])")
        assertFalse("(contains [\"lorem\"] [\"foo\" \"bar\"])")
        assertFalse("(contains [\"lorem\"] nil)")

        assertTrue("(containsAll \"foo\" [\"foo\" \"bar\"])")
        assertTrue("(containsAll [\"foo\"] [\"foo\" \"bar\"])")
        assertTrue("(containsAll [\"foo\" \"bar\"] [\"foo\" \"bar\" \"baz\"])")
        assertFalse("(containsAll [\"foo\" \"lorem\"] [\"foo\" \"bar\"])")
        assertFalse("(containsAll [\"lorem\"] [\"foo\" \"bar\"])")
        assertFalse("(containsAll [\"lorem\"] nil)")
    }

    func testStringCast() {
        assertTrue("(= (write-to-string 2) \"2\")")
        assertTrue("(= (write-to-string 2345678.123) \"2345678.123\")")
        assertTrue("(= (write-to-string true) \"true\")")
        assertTrue("(= (write-to-string false) \"false\")")
        assertTrue("(= (write-to-string \"ok\") \"ok\")")
        assertTrue("(= (write-to-string nil) nil)")

        assertEvaluationError("(write-to-string [\"test\"])")
    }

    func testStringToInteger() {
        assertTrue("(= (parse-string \"2345678.123\") 2345678.123)")
        assertTrue("(= (parse-string \"2\") 2)")
        assertTrue("(= (parse-string nil) nil)")

        assertEvaluationError("(parse-string [\"test\"])")
        assertEvaluationError("(parse-string 2)")
        assertEvaluationError("(parse-string true)")
    }

    func testCaseOperators() {
        //TODO make tests using turkish locale and i
        assertTrue("(= (upper \"ilower\") \"ILOWER\")")
        assertTrue("(= (upper [\"first\" \"second\"]) [\"FIRST\" \"SECOND\"])")
        assertFalse("(= (upper [\"first\" \"second\"]) [\"first\" \"second\"])")
        assertTrue("(= (upper nil) nil)")

        assertEvaluationError("(upper true)")
        assertEvaluationError("(upper 2)")

        assertTrue("(= (lower \"ILOWER\") \"ilower\")")
        assertTrue("(= (lower [\"FIRST\" \"SECOND\"]) [\"first\" \"second\"])")
        assertFalse("(= (lower [\"FIRST\" \"SECOND\"]) [\"FIRST\" \"SECOND\"])")
        assertTrue("(= (lower nil) nil)")

        assertEvaluationError("(lower true)")
        assertEvaluationError("(lower 2)")
    }

    /* Unfortunately testing performance is not possible, as it runs too fast on a computer
     func testPerformanceExample() {
     // This is an example of a performance test case.
     self.measure {
     let program = BALispParser(expression: "(and (= 2 2) (contains [\"foo\" \"bar\"] [\"baz\" \"bar\" \"foo\"]) (= `foo` \"bar\"))").parse()
     if let program = program as? BALReducable {
     program.reduce(BALEmptyEvaluationContext())
     } else {

     }
     }
     }*/

    func assertTrue(_ expression: String, file: StaticString = #filePath, line: UInt = #line) {
        assertBoolean(expression, expectedResult: true, file: file, line: line)
    }

    func assertFalse(_ expression: String, file: StaticString = #filePath, line: UInt = #line) {
        assertBoolean(expression, expectedResult: false, file: file, line: line)
    }

    func assertParsingError(_ expression: String, file: StaticString = #filePath, line: UInt = #line) {
        let program = BALispParser(expression: expression).parse()
        guard let error = program as? BALErrorValue,
            error.kind == .typeParser
        else {
            XCTFail("Expression should result in a parsing error: \(expression)", file: file, line: line)
            return
        }
    }

    func assertEvaluationError(_ expression: String, file: StaticString = #filePath, line: UInt = #line) {
        let result = evaluate(expression: expression)
        guard let error = result as? BALErrorValue,
            error.kind == .typeError
        else {
            XCTFail("Expression should result in a runtime error: \(expression)", file: file, line: line)
            return
        }
    }

    func assertBoolean(_ expression: String, expectedResult: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let result = evaluate(expression: expression)
        switch result {
            case let error as BALErrorValue:
                if error.kind == .typeParser {
                    XCTFail(
                        "Expression should be \(expectedResult), but could not be parsed: \(expression) Error: \(error)",
                        file: file, line: line)
                    return
                }
                XCTFail(
                    "Expression should be \(expectedResult), but errorred: \(expression) Error: \(error)", file: file,
                    line: line)
            case let result as BALPrimitiveValue:
                if result.type != .bool {
                    XCTFail("Expression result should be boolean", file: file, line: line)
                    return
                }

                if let boolValue = (result.value as? NSNumber)?.boolValue {
                    XCTAssert(
                        boolValue == expectedResult, "Expression result should be \(expectedResult): \(expression)",
                        file: file, line: line)
                    return
                }

                XCTFail(
                    "Expression result is of type bool, but the actual value could not be extracted. Looks like an internal error",
                    file: file, line: line)
            default:
                XCTFail(
                    "Expression should be \(expectedResult), but executing it resulted in an unexpected value: \(expression)",
                    file: file, line: line)
        }
    }

    // Exact same as the assert(expression, parseTo) method, but allows
    // Swift to transform the array literal into a S-Expression implicitly
    func assert(
        expression: String, parsesTo expectedAST: LiteralSExpression, file: StaticString = #file, line: UInt = #line
    ) {
        assert(expression: expression, parsesTo: expectedAST as BALValue, file: file, line: line)
    }

    func assert(expression: String, parsesTo expectedAST: BALValue, file: StaticString = #filePath, line: UInt = #line)
    {
        let parsedExpression = parse(expression: expression)
        XCTAssertTrue(
            parsedExpression.isEqual(expectedAST),
            "Expression \(expression) does not parses to expected AST: \(expectedAST)", file: file, line: line)
    }

    func parse(expression: String) -> BALValue {
        return BALispParser(expression: expression).parse()
    }

    func evaluate(expression: String) -> BALValue {
        let program = BALispParser(expression: expression).parse()
        if let program = program as? BALReducable {
            return program.reduce(context)
        }
        return program
    }
}

@objc class TestsEvaluationContext: NSObject, BALEvaluationContext {
    func resolveVariableNamed(_ name: String) -> BALValue? {
        if name.lowercased() == "foo" {
            return BALPrimitiveValue.init(string: "bar")
        }
        return BALPrimitiveValue.nil()
    }

}

class LiteralSExpression: BALSExpression, ExpressibleByArrayLiteral {
    required convenience init(arrayLiteral elements: BALValue...) {
        self.init(values: elements)
    }
}

class MockOperator: BALOperatorValue {
    convenience init(_ symbol: String) {
        self.init(with: BALOperator(symbol: symbol, handler: { _, _ in return BALPrimitiveValue.nil() }))
    }
}
