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
      let packages = userInfo.flatMap {
         name, arguments in
         return Package(name: name, arguments: arguments)
      }

      Realm.write {
         realm in
         let history = realm.currentHistory
         for package in packages {
            switch package {
            case .Start(let id):
               let interval = Interval()
               interval.id = id
               history.addInterval(interval)
               history.activateInterval(interval)
            case .Stop(let id):
               if let interval = realm.objectForPrimaryKey(Interval.self, key: id) {
                  history.deactivateInterval(interval)
               }
            case .Data(let id, let data):
               if let interval = realm.objectForPrimaryKey(Interval.self, key: id) {
                  data.forEach {
                     history.addData($0, toInterval: interval)
                  }
               }
            }
         }
      }
   }
}
