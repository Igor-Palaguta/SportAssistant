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

      if packages.isEmpty {
         return
      }

      let historyController = HistoryController()
      for package in packages {
         switch package {
         case .Start(let id, let start):
            historyController.addTrainingWithId(id, start: start, activate: true)
         case .Stop(let id):
            if let training = historyController[id] {
               historyController.deactivateTraining(training)
            }
         case .Synchronize(let id, let start, let data):
            historyController.synchronizeTrainingWithId(id, start: start, data: data)
         case .Delete(let id):
            if let training = historyController[id] {
               historyController.deleteTraining(training)
            }
         case .Data(let id, let index, let data):
            if let training = historyController[id]
               where (training.currentCount < index + data.count)
                  && (training.currentCount >= index) {
                     let newData = data[training.currentCount-index..<data.count]
                     historyController.appendDataFromArray(newData, toTraining: training)
            }
         }
      }
   }
}
