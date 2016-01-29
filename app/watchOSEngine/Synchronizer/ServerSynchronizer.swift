import Foundation
import WatchConnectivity

struct DataBuffer {
   let createdDate: NSDate
   let trainingId: String
   let position: Int
   let data: [AccelerationEvent]

   func dataBufferByAddingData(data: [AccelerationEvent]) -> DataBuffer {
      return DataBuffer(createdDate: self.createdDate,
         trainingId: self.trainingId,
         position: self.position,
         data: self.data + data)
   }
}

protocol DataBufferManagerDelegate: class {
   func dataBufferManager(manager: DataBufferManager, sendBuffer buffer: DataBuffer)
}

class DataBufferManager {

   weak var delegate: DataBufferManagerDelegate?

   private var buffer: DataBuffer?
   private let sendLimit: Int = 100
   private let flushTraining: NSTimeInterval = 1

   init(delegate: DataBufferManagerDelegate) {
      self.delegate = delegate
   }

   func sendData(data: [AccelerationEvent], fromTraining trainingId: String, position: Int) {
      if let buffer = self.buffer
         where buffer.trainingId == trainingId
            && buffer.position + buffer.data.count == position {
               let combinedBuffer = buffer.dataBufferByAddingData(data)
               self.buffer = combinedBuffer
               let shouldFlush = combinedBuffer.data.count >= self.sendLimit
                  || NSDate().timeIntervalSinceDate(combinedBuffer.createdDate) > self.flushTraining
               if shouldFlush {
                  self.flush()
               }
      } else {
         self.flush()
         self.buffer = DataBuffer(createdDate: NSDate(),
            trainingId: trainingId,
            position: position,
            data: data)
      }
   }

   func flush() {
      if let buffer = self.buffer {
         self.delegate?.dataBufferManager(self, sendBuffer: buffer)
         self.buffer = nil
      }
   }
}

public final class ServerSynchronizer: NSObject {

   public static let defaultServer = ServerSynchronizer()

   private lazy var bufferManager: DataBufferManager = DataBufferManager(delegate: self)

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
      NSLog("sendPackage %@", message)
      self.session!.transferUserInfo(message)
   }

   public func startTraining(training: Training) {
      self.sendPackage(.Start(id: training.id,
         start: training.start,
         tagId: training.tags.first?.id))
   }

   public func stopTraining(training: Training) {
      self.bufferManager.flush()
      self.sendPackage(.Stop(id: training.id))
   }

   public func synchronizeTraining(training: Training) {
      self.sendPackage(.Synchronize(id: training.id,
         start: training.start,
         tagId: training.tags.first?.id,
         data: Array(training.data)))
   }

   public func sendData(data: [AccelerationEvent], forTraining training: Training) {
      if let first = data.first, position = training.data.indexOf(first) {
         self.bufferManager.sendData(data, fromTraining: training.id, position: position)
      } else {
         fatalError("Incorrect training data")
      }
   }
}

extension ServerSynchronizer: WCSessionDelegate {
   public func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {
   }

   public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
      let packages = applicationContext.flatMap {
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
         default:
            fatalError()
         }
      }
   }
}

extension ServerSynchronizer: DataBufferManagerDelegate {
   func dataBufferManager(manager: DataBufferManager, sendBuffer buffer: DataBuffer) {
      self.sendPackage(.Data(id: buffer.trainingId, position: buffer.position, data: buffer.data))
   }
}
