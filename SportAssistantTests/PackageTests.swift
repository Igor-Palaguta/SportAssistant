//
//  PackageTests.swift
//  SportAssistant
//
//  Created by Igor Palaguta on 07.01.16.
//  Copyright © 2016 Spangle. All rights reserved.
//

import XCTest

@testable import SportAssistant

class PackageTests: XCTestCase {

   override func setUp() {
      super.setUp()
      // Put setup code here. This method is called before the invocation of each test method in the class.
   }

   override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
      super.tearDown()
   }

   func testStart() {
      let date = NSDate()
      let start = Package.Start("1", date)

      let message = start.toMessage()

      let packages = message.flatMap {
         name, arguments in
         return Package(name: name, arguments: arguments)
      }

      XCTAssertTrue(packages.count == 1)

      let serializedStart = packages.first!

      if case .Start(let intervalId, let startDate) = serializedStart where intervalId == "1" && startDate == date {
         XCTAssertTrue(true)
      } else {
         XCTAssertTrue(false)
      }

      
   }

   func testPerformanceExample() {
      // This is an example of a performance test case.
      self.measureBlock {
         // Put the code you want to measure the time of here.
      }
   }

}
