//
//  HistoryTests.swift
//  SportAssistant
//
//  Created by Igor Palaguta on 26.12.15.
//  Copyright © 2015 Spangle. All rights reserved.
//

import XCTest
import RealmSwift
@testable import SportAssistant

class HistoryTests: XCTestCase {
    
   override func setUp() {
      super.setUp()
      Realm.configure()
      // Put setup code here. This method is called before the invocation of each test method in the class.
   }

   override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
      super.tearDown()

      let realm = try! Realm()
      try! realm.write {
         realm.deleteAll()
      }
   }

   func testTotal() {
      let data1 = AccelerationData(x: 3, y: 4, z: 12, timestamp: 0)
      XCTAssertTrue(data1.total == 13)

      let data2 = AccelerationData(x: 4, y: 5, z: 20, timestamp: 0)
      XCTAssertTrue(data2.total == 21)
   }

   func testHistory() {
      let historyController = HistoryController()
      print("historyController count \(historyController.intervalsCount)")
      XCTAssertTrue(historyController.intervalsCount == 0)

      let interval1 = Interval()
      historyController.addInterval(interval1, activate: true)
      XCTAssertTrue(historyController.intervals.count == 1)
      XCTAssertTrue(historyController.intervalsCount == 1)
      XCTAssertTrue(historyController.active == interval1)

      let interval2 = Interval()
      historyController.addInterval(interval2)
      XCTAssertTrue(historyController.active == interval1)

      historyController.deactivateInterval(interval2)
      XCTAssertTrue(historyController.active == interval1)

      historyController.deactivateInterval(interval1)
      XCTAssertTrue(historyController.active == nil)

      let data1 = AccelerationData(x: 1, y: 2, z: 3, timestamp: 0)
      let data2 = AccelerationData(x: 3, y: 4, z: 12, timestamp: 0)
      historyController.addData([data1, data2], toInterval: interval1)

      XCTAssertTrue(interval1.currentCount == 2)

      let data3 = AccelerationData(x: 3, y: 5, z: 11, timestamp: 0)
      let data4 = AccelerationData(x: 3, y: 6, z: 10, timestamp: 0)
      historyController.addData([data3, data4], toInterval: interval1)

      XCTAssertTrue(interval1.data.count == 4)
      XCTAssertTrue(interval1.currentCount == 4)
      XCTAssertTrue(interval1.best == 13)
      XCTAssertTrue(historyController.best == 13)
   }
}
