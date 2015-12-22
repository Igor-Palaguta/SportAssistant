import WatchKit
import Foundation
import WatchConnectivity

protocol TrainingInterfaceControllerDelegate: class {
   func trainingInterfaceController(controller: TrainingInterfaceController,
      didAddData data: BaseAccelerationData,
      toTraining training: Training)

   func trainingInterfaceController(controller: TrainingInterfaceController,
      didStopTraining training: Training)
}

class TrainingInterfaceController: WKInterfaceController {

   weak var delegate: TrainingInterfaceControllerDelegate?

   @IBOutlet weak var countLabel: WKInterfaceLabel!
   @IBOutlet weak var bestLabel: WKInterfaceLabel!
   @IBOutlet weak var worstLabel: WKInterfaceLabel!
   @IBOutlet weak var averageLabel: WKInterfaceLabel!

   private var best: Double = 0 {
      didSet {
         self.bestLabel.setText(NSNumberFormatter.formatAccelereration(self.best))
      }
   }

   private var suspender: BackgroundSuspender?
   private var training: Training?

   private lazy var accelerometer: Accelerometer = {
      [unowned self] in
      let accelerometer = Accelerometer()
      accelerometer.delegate = self
      return accelerometer
      }()

   private lazy var session: WCSession? = {
      if WCSession.isSupported() {
         let session = WCSession.defaultSession()
         session.activateSession()
         return session
      }
      return nil
   }()

   deinit {
      self.suspender?.stop()
   }

   private func stopRecording() {
      if let training = self.training {
         self.delegate?.trainingInterfaceController(self, didStopTraining: training)
         self.session?.transferUserInfo(["stop": training.id])
      }
      self.accelerometer.stop()
      self.suspender?.stop()
      self.suspender = nil
      self.training = nil
   }

   private func startRecording() {
      self.training = Training()
      self.accelerometer.start()
      self.suspender = BackgroundSuspender()
      self.suspender?.suspend()
   }

   override func didDeactivate() {
      super.didDeactivate()
   }

   override func willActivate() {
      super.willActivate()
      self.suspender?.suspend()
   }

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      if let delegate = context as? TrainingInterfaceControllerDelegate {
         self.delegate = delegate
      }

      self.startRecording()
   }

   @IBAction private func stopAction(_: WKInterfaceButton) {
      self.stopRecording()
      self.dismissController()
   }

   @IBAction private func restartAction(_: WKInterfaceButton) {
      self.stopRecording()
      self.startRecording()
   }
}

extension TrainingInterfaceController: AccelerometerDelegate {
   func accelerometer(accelerometer: Accelerometer, didReceiveData accelerometerData: BaseAccelerationData) {
      guard let training = self.training else {
         return
      }
      let data = AccelerationData(data: accelerometerData)
      History.defaultHistory.addData(data, toTraining: training)
      self.bestLabel.setText(NSNumberFormatter.formatAccelereration(training.best))

      self.delegate?.trainingInterfaceController(self,
         didAddData: data,
         toTraining: training)

      let userInfo: [String: AnyObject] = ["acceleration": data.attributes, "intervalId": training.id]
      self.session?.transferUserInfo(userInfo)
   }
}
