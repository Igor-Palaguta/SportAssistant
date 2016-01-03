import WatchKit
import Foundation
import YOChartImageKit

final class ChartInterfaceController: WKInterfaceController {

   @IBOutlet private weak var chartView: WKInterfaceImage!

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      let chart = YOLineChartImage()
      chart.strokeWidth = 1.0
      let interval = context as! Interval
      chart.values = interval.data.map { $0.total }
      let frame = CGRect(origin: .zero, size: contentFrame.size)
      let image = chart.drawImage(frame, scale: WKInterfaceDevice.currentDevice().screenScale)
      self.chartView.setImage(image)
   }

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

}
