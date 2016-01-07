import Foundation
import WatchConnectivity

struct DataBuffer {
   let createdDate: NSDate
   let intervalId: String
   let offset: Int
   let data: [AccelerationData]

   func dataBufferByAddingData(data: [AccelerationData]) -> DataBuffer {
      return DataBuffer(createdDate: self.createdDate,
         intervalId: self.intervalId,
         offset: self.offset,
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

   func sendData(data: [AccelerationData], fromInterval intervalId: String, withOffset offset: Int) {
      if let buffer = self.buffer
         where buffer.intervalId == intervalId
            && buffer.offset + buffer.data.count == offset {
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
            offset: offset,
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

   private func forceSendPackage(package: Package) {
      let message = package.toMessage()
      self.session!.transferUserInfo(message)
   }

   func sendPackage(package: Package) {
      switch package {
      case .Data(let intervalId, let offset, let data):
         self.bufferManager.sendData(data, fromInterval: intervalId, withOffset: offset)
         return
      case .Stop(_):
         self.bufferManager.flush()
      default:
         break
      }

      self.forceSendPackage(package)
   }
}

extension ServerSynchronizer: WCSessionDelegate {
   func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: NSError?) {
   }
}

extension ServerSynchronizer: DataBufferManagerDelegate {
   func dataBufferManager(manager: DataBufferManager, sendBuffer buffer: DataBuffer) {
      self.forceSendPackage(.Data(buffer.intervalId, buffer.offset, buffer.data))
   }
}
