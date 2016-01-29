import WatchKit
import Foundation
import YOChartImageKit
import watchOSEngine

final class ChartInterfaceController: WKInterfaceController {

   @IBOutlet private weak var emptyView: WKInterfaceObject!
   @IBOutlet private weak var chartView: WKInterfaceImage!

   private var training: Training!
   private var didActivateBefore = false

   override func awakeWithContext(context: AnyObject?) {
      super.awakeWithContext(context)

      self.training = context as! Training
   }

   override func willActivate() {
      // This method is called when watch view controller is about to be visible to user
      super.willActivate()

      guard !self.didActivateBefore else {
         return
      }

      let activities = self.training.activityEvents.map { $0.total }

      if activities.isEmpty {
         self.emptyView.setHidden(false)
      } else {
         let chart = YOLineChartImage()
         chart.strokeWidth = 1.0
         chart.strokeColor = UIColor(named: .Base)
         chart.fillColor = UIColor(named: .Base).colorWithAlphaComponent(0.5)
         chart.values = activities
         let frame = CGRect(origin: .zero, size: contentFrame.size)
         let image = chart.drawImage(frame, scale: WKInterfaceDevice.currentDevice().screenScale)
         self.chartView.setImage(image)
         self.chartView.setHidden(false)
      }

      self.didActivateBefore = true
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

}
