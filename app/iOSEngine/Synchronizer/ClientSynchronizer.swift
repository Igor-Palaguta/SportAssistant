import Foundation
import WatchConnectivity

public final class ClientSynchronizer: NSObject {

   public static let defaultClient = ClientSynchronizer()

   private var session: WCSession?

   public func start() {
      if self.session == nil && WCSession.isSupported() {
         let session = WCSession.defaultSession()
         session.delegate = self
         session.activateSession()
         self.session = session
      }
   }

   public func synchronizeTags() {
      let storage = StorageController()
      let message = Package.Tags(Array(storage.tags)).toMessage()
      do {
         try self.session?.updateApplicationContext(message)
      } catch {
      }
   }
}

extension ClientSynchronizer: WCSessionDelegate {
   public func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {

   }

   public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {

      NSLog("didReceiveUserInfo %@", userInfo)

      let packages = userInfo.flatMap {
         name, arguments in
         return Package(name: name, arguments: arguments)
      }

      if packages.isEmpty {
         return
      }

      let storage = StorageController()
      for package in packages {
         switch package {
         case .Start(let id, let start, let tagId):
            storage.addTrainingWithId(id, start: start, tagId: tagId, activate: true)
         case .Stop(let id):
            if let training = storage[id] {
               storage.deactivateTraining(training)
            }
         case .Synchronize(let id, let start, let tagId, let events):
            storage.synchronizeTrainingWithId(id, start: start, tagId: tagId, events: events)
         case .Delete(let id):
            if let training = storage[id] {
               storage.deleteTraining(training)
            }
         case .Events(let id, let index, let events):
            if let training = storage[id]
               where (training.currentCount < index + events.count)
                  && (training.currentCount >= index) {
                     let newEvents = events[training.currentCount-index..<events.count]
                     storage.appendEvents(newEvents, toTraining: training)
            }
         case .Tags(_):
            fatalError()
         }
      }
   }
}
