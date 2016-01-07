import Foundation
import WatchConnectivity

struct DataBuffer {
   let createdDate: NSDate
   let intervalId: String
   let position: Int
   let data: [AccelerationData]

   func dataBufferByAddingData(data: [AccelerationData]) -> DataBuffer {
      return DataBuffer(createdDate: self.createdDate,
         intervalId: self.intervalId,
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
   private let flushInterval: NSTimeInterval = 1

   init(delegate: DataBufferManagerDelegate) {
      self.delegate = delegate
   }

   func sendData(data: [AccelerationData], fromInterval intervalId: String, position: Int) {
      if let buffer = self.buffer
         where buffer.intervalId == intervalId
            && buffer.position + buffer.data.count == position {
               let combinedBuffer = buffer.dataBufferByAddingData(data)
               self.buffer = combinedBuffer
               let shouldFlush = combinedBuffer.data.count >= self.sendLimit
                  || NSDate().timeIntervalSinceDate(combinedBuffer.createdDate) > self.flushInterval
               if shouldFlush {
                  self.flush()
               }
      } else {
         self.flush()
         self.buffer = DataBuffer(createdDate: NSDate(),
            intervalId: intervalId,
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

final class ServerSynchronizer: NSObject {

   static let defaultServer = ServerSynchronizer()

   private lazy var bufferManager: DataBufferManager = DataBufferManager(delegate: self)

   private lazy var session: WCSession? = {
      if WCSession.isSupported() {
         let session = WCSession.defaultSession()
         session.delegate = self
         session.activateSession()
         return session
      }
      return nil
   }()

   private func sendPackage(package: Package) {
      let message = package.toMessage()
      self.session!.transferUserInfo(message)
   }

   func startInterval(interval: Interval) {
      self.sendPackage(.Start(id: interval.id, start: interval.start))
   }

   func stopInterval(interval: Interval) {
      self.bufferManager.flush()
      self.sendPackage(.Stop(id: interval.id))
   }

   func synchronizeInterval(interval: Interval) {
      self.sendPackage(.Synchronize(id: interval.id, start: interval.start, data: Array(interval.data)))
   }

   func sendData(data: [AccelerationData], forInterval interval: Interval) {
      if let first = data.first, position = interval.data.indexOf(first) {
         self.bufferManager.sendData(data, fromInterval: interval.id, position: position)
      } else {
         fatalError("Incorrect interval data")
      }
   }
}

extension ServerSynchronizer: WCSessionDelegate {
   func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {
   }
}

extension ServerSynchronizer: DataBufferManagerDelegate {
   func dataBufferManager(manager: DataBufferManager, sendBuffer buffer: DataBuffer) {
      self.sendPackage(.Data(id: buffer.intervalId, position: buffer.position, data: buffer.data))
   }
}
