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

   func synchronizeTags() {
      let historyController = HistoryController()
      let message = Package.Tags(Array(historyController.tags)).toMessage()
      do {
         try self.session?.updateApplicationContext(message)
      } catch {
      }
   }
}

extension ClientSynchronizer: WCSessionDelegate {
   func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {

   }

   func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {

      NSLog("didReceiveUserInfo %@", userInfo)

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
         case .Start(let id, let start, let tagId):
            historyController.addTrainingWithId(id, start: start, tagId: tagId, activate: true)
         case .Stop(let id):
            if let training = historyController[id] {
               historyController.deactivateTraining(training)
            }
         case .Synchronize(let id, let start, let tagId, let data):
            historyController.synchronizeTrainingWithId(id, start: start, tagId: tagId, data: data)
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
         case .Tags(_):
            fatalError()
         }
      }
   }
}
