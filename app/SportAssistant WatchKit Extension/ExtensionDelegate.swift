import WatchKit
import RealmSwift

class ExtensionDelegate: NSObject, WKExtensionDelegate {

   func applicationDidFinishLaunching() {
      Realm.configure()
      ServerSynchronizer.defaultServer.start()
   }

   func applicationDidBecomeActive() {
   }

   func applicationWillResignActive() {
   }
}
