import WatchKit
import Foundation

protocol TrainingInterfaceControllerDelegate: class {
   func trainingInterfaceController(controller: TrainingInterfaceController, didReceiveAccelerometerData data: AccelerometerData)
}

class TrainingInterfaceController: WKInterfaceController {

   weak var delegate: TrainingInterfaceControllerDelegate?

   @IBOutlet weak var countLabel: WKInterfaceLabel!
   @IBOutlet weak var bestLabel: WKInterfaceLabel!
   @IBOutlet weak var worstLabel: WKInterfaceLabel!
   @IBOutlet weak var averageLabel: WKInterfaceLabel!

   private lazy var accelerometer: Accelerometer = {
      [unowned self] in
      let accelerometer = Accelerometer()
      accelerometer.delegate = self
      return accelerometer
      }()

   private func stopRecording() {
      self.accelerometer.stop()
   }

   private func startRecording() {
      self.bestLabel.setText(nil)
      self.accelerometer.start()
   }

   override func didDeactivate() {
      super.didDeactivate()
      NSLog("didDeactivate")
   }

   override func willActivate() {
      super.willActivate()
      NSLog("willActivate")
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
      self.startRecording()
   }
}

extension TrainingInterfaceController: AccelerometerDelegate {
   func accelerometer(accelerometer: Accelerometer, didReceiveData data: AccelerometerData) {
      self.delegate?.trainingInterfaceController(self, didReceiveAccelerometerData: data)
   }
}

