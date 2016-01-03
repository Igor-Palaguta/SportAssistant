import Foundation
import WatchConnectivity

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

      let historyController = HistoryController()
      for package in packages {
         switch package {
         case .Start(let id):
            let interval = Interval(id: id)
            historyController.addInterval(interval, activate: true)
         case .Stop(let id):
            if let interval = historyController[id] {
               historyController.deactivateInterval(interval)
            }
         case .Delete(let id):
            if let interval = historyController[id] {
               historyController.deleteInterval(interval)
            }
         case .Data(let id, let data):
            if let interval = historyController[id] {
               historyController.addData(data, toInterval: interval)
            }
         }
      }
   }
}
