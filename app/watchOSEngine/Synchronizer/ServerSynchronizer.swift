import Foundation
import WatchConnectivity

struct EventsBuffer {
   let createdDate: NSDate
   let trainingId: String
   let position: Int
   let events: [AccelerationEvent]

   func eventsBufferByAddingEvents(events: [AccelerationEvent]) -> EventsBuffer {
      return EventsBuffer(createdDate: self.createdDate,
         trainingId: self.trainingId,
         position: self.position,
         events: self.events + events)
   }
}

protocol EventsBufferManagerDelegate: class {
   func eventsBufferManager(manager: EventsBufferManager, sendBuffer buffer: EventsBuffer)
}

class EventsBufferManager {

   weak var delegate: EventsBufferManagerDelegate?

   private var buffer: EventsBuffer?
   private let sendLimit: Int = 100
   private let flushTraining: NSTimeInterval = 1

   init(delegate: EventsBufferManagerDelegate) {
      self.delegate = delegate
   }

   func sendEvents(events: [AccelerationEvent], fromTraining trainingId: String, position: Int) {
      if let buffer = self.buffer
         where buffer.trainingId == trainingId
            && buffer.position + buffer.events.count == position {
               let combinedBuffer = buffer.eventsBufferByAddingEvents(events)
               self.buffer = combinedBuffer
               let shouldFlush = combinedBuffer.events.count >= self.sendLimit
                  || NSDate().timeIntervalSinceDate(combinedBuffer.createdDate) > self.flushTraining
               if shouldFlush {
                  self.flush()
               }
      } else {
         self.flush()
         self.buffer = EventsBuffer(createdDate: NSDate(),
            trainingId: trainingId,
            position: position,
            events: events)
      }
   }

   func flush() {
      if let buffer = self.buffer {
         self.delegate?.eventsBufferManager(self, sendBuffer: buffer)
         self.buffer = nil
      }
   }
}

public final class ServerSynchronizer: NSObject {

   public static let defaultServer = ServerSynchronizer()

   private lazy var bufferManager: EventsBufferManager = EventsBufferManager(delegate: self)

   private var session: WCSession?

   public func start() {
      if self.session == nil && WCSession.isSupported() {
         let session = WCSession.defaultSession()
         session.delegate = self
         session.activateSession()
         self.session = session
      }
   }

   private func sendPackage(package: Package) {
      let message = package.toMessage()
      //NSLog("sendPackage %@", message)
      self.session!.transferUserInfo(message)
   }

   public func startTraining(training: Training) {
      self.sendPackage(.Start(id: training.id,
         start: training.start,
         tagIds: training.tags.map { $0.id }))
   }

   public func stopTraining(training: Training) {
      self.bufferManager.flush()
      self.sendPackage(.Stop(id: training.id))
   }

   public func synchronizeTraining(training: Training) {
      self.sendPackage(.Synchronize(id: training.id,
         start: training.start,
         tagIds: training.tags.map { $0.id },
         events: Array(training.events)))
   }

   public func sendEvents(events: [AccelerationEvent], forTraining training: Training) {
      if let first = events.first, position = training.events.indexOf(first) {
         self.bufferManager.sendEvents(events, fromTraining: training.id, position: position)
      } else {
         fatalError("Incorrect training data")
      }
   }
}

extension ServerSynchronizer: WCSessionDelegate {
   public func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {
   }

   private func processMessage(message: [String : AnyObject]) {
      //NSLog("processMessage %@", message)
      let packages = message.flatMap {
         name, arguments in
         return Package(name: name, arguments: arguments)
      }

      if packages.isEmpty {
         return
      }

      let storage = StorageController()
      for package in packages {
         switch package {
         case .Tags(let tags):
            storage.assignTags(tags)
         case .ChangeTrainingTags(let id, let tagIds):
            if let training = storage[id] {
               let tags = tagIds.flatMap { storage.realm.objectForPrimaryKey(Tag.self, key: $0) }
               storage.assignTags(tags, forTraining: training)
            }
         default:
            fatalError()
         }
      }
   }

   public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
      self.processMessage(applicationContext)
   }

   public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
      self.processMessage(userInfo)
   }
}

extension ServerSynchronizer: EventsBufferManagerDelegate {
   func eventsBufferManager(manager: EventsBufferManager, sendBuffer buffer: EventsBuffer) {
      self.sendPackage(.Events(id: buffer.trainingId, position: buffer.position, events: buffer.events))
   }
}
