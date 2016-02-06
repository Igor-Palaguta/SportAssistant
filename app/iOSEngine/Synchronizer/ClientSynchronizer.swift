import Foundation
import WatchConnectivity
import RealmSwift

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

   public func sendTags() {
      let storage = StorageController()
      let message = Package.Tags(Array(storage.tags)).toMessage()
      do {
         try self.session?.updateApplicationContext(message)
      } catch {
      }
   }

   private func sendPackage(package: Package) {
      let message = package.toMessage()
      //NSLog("sendPackage %@", message)
      self.session!.transferUserInfo(message)
   }

   public func sendTagsOfTraining(training: Training) {
      let package = Package.ChangeTrainingTags(id: training.id, tagIds: Array(training.tags.map { $0.id }))
      self.sendPackage(package)
   }
}

extension ClientSynchronizer: WCSessionDelegate {
   public func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {

   }

   public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {

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
         case .Start(let id, let start, let tagIds):
            storage.addTrainingWithId(id, start: start, tagIds: tagIds, activate: true)
         case .Stop(let id):
            if let training = storage[id] {
               storage.deactivateTraining(training)
            }
         case .Synchronize(let id, let start, let tagIds, let events):
            storage.synchronizeTrainingWithId(id, start: start, tagIds: tagIds, events: events)
         case .Delete(let id):
            if let training = storage[id] {
               storage.deleteTraining(training)
            }
         case .Events(let id, let index, let events):
            if let training = storage[id]
               where (training.events.count < index + events.count)
                  && (training.events.count >= index) {
                     let newEvents = events[training.events.count-index..<events.count]
                     storage.appendEvents(newEvents, toTraining: training)
            }
         case .Tags(_), .ChangeTrainingTags(_):
            fatalError()
         }
      }
   }
}
