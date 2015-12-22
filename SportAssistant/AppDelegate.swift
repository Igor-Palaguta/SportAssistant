//
//  AppDelegate.swift
//  SportAssistant
//
//  Created by Igor Palaguta on 07.12.15.
//  Copyright © 2015 Spangle. All rights reserved.
//

import UIKit
import WatchConnectivity
import RealmSwift
import SwiftyTimer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

   var window: UIWindow?

   func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
      // Override point for customization after application launch.

      self.configureRealm()
      self.startWatchSession()
      //self.generateFakeData()

      return true
   }

   func applicationWillResignActive(application: UIApplication) {
      // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
      // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   }

   func applicationDidEnterBackground(application: UIApplication) {
      // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
      // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   }

   func applicationWillEnterForeground(application: UIApplication) {
      // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   }

   func applicationDidBecomeActive(application: UIApplication) {
      // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   }

   func applicationWillTerminate(application: UIApplication) {
      // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
   }


}

private extension AppDelegate {
   func configureRealm() {
      var config = Realm.Configuration()

      let documentsURL = NSFileManager.defaultManager()
         .URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
         .first!

      // Use the default directory, but replace the filename with the username
      config.path = documentsURL
         .URLByAppendingPathComponent("Acceleration.realm")
         .path

      // Set this as the configuration used for the default Realm
      Realm.Configuration.defaultConfiguration = config

      let realm = try! Realm()
      if realm.objects(Achievements.self).isEmpty {
         try! realm.write {
            let achievements = Achievements()
            realm.add(achievements)
         }
      }
   }

   func startWatchSession() {
      if WCSession.isSupported() {
         let session = WCSession.defaultSession()
         session.delegate = self
         session.activateSession()
      }
   }

   func generateFakeData() {
      let intervalId = NSUUID().UUIDString
      NSTimer.every(3.seconds) {
         let data = AccelerationData(x: drand48() * 16 - 8,
            y: drand48() * 16 - 8,
            z: drand48() * 16 - 8,
            date: NSDate())
         let realm = try! Realm()
         realm.addAccelerationData(data, intervalId: intervalId)
      }
   }
}

extension AppDelegate: WCSessionDelegate {
   func sessionWatchStateDidChange(session: WCSession) {

   }

   func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
      dispatch_async(dispatch_get_main_queue()) {
         if let intervalId = userInfo["stop"] as? String {
            let realm = try! Realm()
            if let interval = realm.objectForPrimaryKey(Interval.self, key: intervalId) {
               try! realm.write {
                  interval.completed = true
               }
            }
         } else if let acceleration = userInfo["acceleration"] as? [String: AnyObject],
            x = acceleration["x"] as? Double,
            y = acceleration["y"] as? Double,
            z = acceleration["z"] as? Double,
            date = acceleration["date"] as? NSDate,
            intervalId = userInfo["intervalId"] as? String {
               let data = AccelerationData(x: x, y: y, z: z, date: date)
               let realm = try! Realm()
               realm.addAccelerationData(data, intervalId: intervalId)
         }
      }
   }
}

