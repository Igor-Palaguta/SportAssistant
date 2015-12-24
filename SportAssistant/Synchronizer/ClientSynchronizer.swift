import Foundation
import WatchConnectivity
import RealmSwift

final class ClientSynchronizer: NSObject {

   static let defaultClient = ClientSynchronizer()

   private var session: WCSession?

   func start() {
      if self.session == nil && WCSession.isSupported() {
         let session = WCSession.defaultSession()
         session.delegate = self
         session.activateSession()
         self.session = session
      }
   }
}

extension ClientSynchronizer: WCSessionDelegate {
   func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {

   }

   func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
      NSLog("didReceiveUserInfo: %@", userInfo)
      let packages = userInfo.flatMap {
         name, arguments in
         return Package(name: name, arguments: arguments)
      }

      Realm.write {
         realm in
         for package in packages {
            switch package {
            case .Start(let id):
               let interval = Interval()
               interval.id = id
               interval.active = true
               realm.currentHistory.addInterval(interval)
            case .Stop(let id):
               if let interval = realm.objectForPrimaryKey(Interval.self, key: id) {
                  interval.active = false
               }
            case .Data(let id, let data):
               if let interval = realm.objectForPrimaryKey(Interval.self, key: id) {
                  let history = realm.currentHistory
                  data.forEach {
                     history.addData($0, toInterval: interval)
                  }
               }
            }
         }
      }
   }
}
