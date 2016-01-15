import WatchKit
import Foundation
import YOChartImageKit

final class ChartInterfaceController: WKInterfaceController {

   @IBOutlet private weak var chartView: WKInterfaceImage!

   private var interval: Interval!
   private var didActivateBefore = false

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      self.interval = context as! Interval
   }

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()

      NSLog("willActivate")
      if !self.didActivateBefore {
         let chart = YOLineChartImage()
         chart.strokeWidth = 1.0
         chart.values = self.interval.data.map { $0.total }
         let frame = CGRect(origin: .zero, size: contentFrame.size)
         let image = chart.drawImage(frame, scale: WKInterfaceDevice.currentDevice().screenScale)
         self.chartView.setImage(image)
         self.didActivateBefore = true
      }
      NSLog("did willActivate")
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

}
