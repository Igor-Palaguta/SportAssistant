//
//  AnalyzerTests.swift
//  SportAssistant
//
//  Created by Igor Palaguta on 26.12.15.
//  Copyright © 2015 Spangle. All rights reserved.
//

import XCTest
@testable import SportAssistant

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
      let range = Range(initial: 7)
      XCTAssert(range.final == 7)
      XCTAssert(range.initial == 7)
      XCTAssert(range.globalMax == 7)
      XCTAssert(range.globalMin == 7)
      XCTAssert(range.localMinMax.isEmpty)
      XCTAssert(range.growSign == .Zero)

      range.addValue(8)
      range.addValue(-1)
      range.addValue(-3)
      range.addValue(-7)
      range.addValue(-5)
      range.addValue(-3)
      range.addValue(-5)
      range.addValue(-8)
      range.addValue(5)
      XCTAssert(range.final == 5)
      XCTAssert(range.initial == 7)
      XCTAssert(range.globalMax == 8)
      XCTAssert(range.globalMin == -8)
      XCTAssert(range.localMinMax == [8, -7, -3, -8])
      XCTAssert(range.growSign == .Plus)
   }

}
