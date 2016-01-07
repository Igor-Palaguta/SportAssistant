//
//  ExtensionDelegate.swift
//  SportAssistant WatchKit Extension
//
//  Created by Igor Palaguta on 07.12.15.
//  Copyright © 2015 Spangle. All rights reserved.
//

import WatchKit
import RealmSwift

class ExtensionDelegate: NSObject, WKExtensionDelegate {

   func applicationDidFinishLaunching() {
      Realm.configure()
   }

   func applicationDidBecomeActive() {
   }

   func applicationWillResignActive() {
   }
}
