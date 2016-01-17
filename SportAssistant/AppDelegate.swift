//
//  AppDelegate.swift
//  SportAssistant
//
//  Created by Igor Palaguta on 07.12.15.
//  Copyright © 2015 Spangle. All rights reserved.
//

import UIKit
import RealmSwift
import HealthKit
import ReactiveCocoa

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

   private lazy var healthStore = HKHealthStore()
   var window: UIWindow?

   func application(application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

      Realm.configure()
      ClientSynchronizer.defaultClient.start()

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

   func applicationShouldRequestHealthAuthorization(application: UIApplication) {
      self.healthStore.handleAuthorizationForExtensionWithCompletion {
         success, error in

      }
   }

   private func showTraining(training: Training) {
      guard let rootController = self.window?.rootViewController as? UINavigationController else {
         fatalError()
      }
      let trainingController = StoryboardScene.Main.trainingViewController()
      trainingController.training = training
      rootController.viewControllers = [rootController.viewControllers.first!, trainingController]
   }

   func application(application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
      return true
   }

   func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
      print("\(userActivity.userInfo)")
      guard let userInfo = userActivity.userInfo as? [String: AnyObject],
         trainingId = userInfo["id"] as? String,
         start = userInfo["start"] as? NSDate else {
            return false
      }

      let training = HistoryController.mainThreadController.addTrainingWithId(trainingId, start: start)
      self.showTraining(training)
      return true
   }
}
