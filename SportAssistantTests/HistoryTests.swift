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
   }

   func testTotal() {
      let data1 = AccelerationData(x: 3, y: 4, z: 12, date: NSDate())
      XCTAssertTrue(data1.total == 13)

      let data2 = AccelerationData(x: 4, y: 5, z: 20, date: NSDate())
      XCTAssertTrue(data2.total == 21)
   }

   func testHistory() {
      let history = History.currentHistory
      XCTAssert(history.intervalsCount == 0)
      let interval1 = Interval()
      Realm.write {
         realm in
         history.addInterval(interval1)
         realm.add(interval1)
      }
      XCTAssert(interval1.history == history)
      XCTAssert(history.intervals.count == 1)
      XCTAssert(history.intervalsCount == 1)

      history.activateInterval(interval1)
      XCTAssertTrue(history.active == interval1)

      let data1 = AccelerationData(x: 1, y: 2, z: 3, date: NSDate())
      history.addData(data1, toInterval: interval1)

      let data2 = AccelerationData(x: 3, y: 4, z: 12, date: NSDate())
      history.addData(data2, toInterval: interval1)

      XCTAssertTrue(interval1.currentCount == 2)

      let data3 = AccelerationData(x: 3, y: 5, z: 11, date: NSDate())
      history.addData(data3, toInterval: interval1)

      let data4 = AccelerationData(x: 3, y: 6, z: 10, date: NSDate())
      history.addData(data4, toInterval: interval1)

      XCTAssertTrue(interval1.data.count == 4)
      XCTAssertTrue(interval1.currentCount == 4)
      XCTAssertTrue(interval1.best == 13)
      XCTAssertTrue(history.best == 13)
   }

}
