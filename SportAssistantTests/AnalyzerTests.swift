//
//  AnalyzerTests.swift
//  SportAssistant
//
//  Created by Igor Palaguta on 26.12.15.
//  Copyright © 2015 Spangle. All rights reserved.
//

import XCTest
@testable import SportAssistant

private extension AccelerationData {
   func p(value: Double) -> PointValue {
      return PointValue(value: value, data: self)
   }

   convenience init(total: Double) {
      self.init(x: total, y: 0, z: 0, timestamp: 0)
   }
}

class AnalyzerTests: XCTestCase {

   override func setUp() {
      super.setUp()
      // Put setup code here. This method is called before the invocation of each test method in the class.
   }

   override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
      super.tearDown()
   }

   func testExample() {
      // This is an example of a functional test case.
      // Use XCTAssert and related functions to verify your tests produce the correct results.
   }

   func testPerformanceExample() {
      // This is an example of a performance test case.
      self.measureBlock {
         // Put the code you want to measure the time of here.
      }
   }

   func testSign() {
      XCTAssert(Sign(value: -0.1) == .Minus)
      XCTAssert(Sign(value: 0.1) == .Plus)
      XCTAssert(Sign(value: 0) == .Zero)
      XCTAssert(Sign(value: -1000) == .Minus)
      XCTAssert(Sign(value: 1000) == .Plus)
   }

   func testRange() {
      let data = AccelerationData(x: 1, y: 1, z: 1, timestamp: 0)

      let range = Range(initial: data.p(7))
      XCTAssertTrue(range.final.value == 7)
      XCTAssertTrue(range.initial.value == 7)
      XCTAssertTrue(range.globalMax.value == 7)
      XCTAssertTrue(range.globalMin.value == 7)
      XCTAssertTrue(range.localMinMax.isEmpty)
      XCTAssertTrue(range.growSign == .Zero)

      range.addValue(data.p(8))
      range.addValue(data.p(-1))
      range.addValue(data.p(-3))
      range.addValue(data.p(-7))
      range.addValue(data.p(-5))
      range.addValue(data.p(-3))
      range.addValue(data.p(-5))
      range.addValue(data.p(-8))
      range.addValue(data.p(5))
      XCTAssertTrue(range.final.value == 5)
      XCTAssertTrue(range.initial.value == 7)
      XCTAssertTrue(range.globalMax.value == 8)
      XCTAssertTrue(range.globalMin.value == -8)
      XCTAssertTrue(range.localMinMax.map({$0.value}) == [8, -7, -3, -8])
      XCTAssertTrue(range.growSign == .Plus)
   }

   func testTableTennisAnalyzer() {
      let analyzer = TableTennisAnalyzer()
      let result1 = analyzer.analyzeData(AccelerationData(total: 1.24684542980376))
      XCTAssertTrue(result1.data.isEmpty)
      let result2 = analyzer.analyzeData(AccelerationData(total: 3.57171658045749))
      XCTAssertTrue(result2.data.isEmpty)
      let result3 = analyzer.analyzeData(AccelerationData(total: 5.45520732717584))
      XCTAssertTrue(result3.data.isEmpty)
      let result4 = analyzer.analyzeData(AccelerationData(total: 4.69492818116718))
      XCTAssertTrue(result4.data.isEmpty)
      let result5 = analyzer.analyzeData(AccelerationData(total: 0.791985977568311))
      XCTAssertTrue(result5.data.count == 4)
   }
}
