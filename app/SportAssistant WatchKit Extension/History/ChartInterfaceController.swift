import WatchKit
import Foundation
import NKWatchChart
import watchOSEngine

private extension Training {

   var chartData: [(total: Double, timestamp: Double)] {
      return self.events.map { (total: $0.total, timestamp: $0.timestamp) }
   }

   var clusteredChartData: [(total: Double, timestamp: Double)] {
      let maximumPoints = 24
      if self.events.count <= maximumPoints {
         return self.chartData
      }

      let clusterDuration: Double = self.duration / Double(maximumPoints)

      var clusteredValues = [Double](count: maximumPoints, repeatedValue: 0)

      for event in self.events {
         let index = min(Int(event.timestamp / clusterDuration), maximumPoints-1)
         if clusteredValues[index] < event.total {
            clusteredValues[index] = event.total
         }
      }

      let yValues: [Double] = (1...maximumPoints).map { Double($0) * clusterDuration }
      return Array(zip(clusteredValues, yValues))
   }

   func chartImageWithSize(size: CGSize) -> UIImage? {
      let chartPoints = self.clusteredChartData

      let chart = NKBarChart(frame: CGRect(origin: .zero, size: size))

      chart.labelMarginTop = 5
      chart.showChartBorder = true
      /*chart.yLabelFormatter = {
         time: CGFloat -> String! in
         return time.formattedSeconds()
      }*/
      chart.xLabels = chartPoints.map { $0.timestamp.formattedSeconds() }
      chart.yValues = chartPoints.map { $0.total }
      chart.yLabelSum = 5
      chart.xLabelSkip = chartPoints.count / 4
      chart.barBackgroundColor = .clearColor()
      chart.barColor = .clearColor()
      chart.strokeColor = UIColor(named: .Base)
      chart.barRadius = 0
      chart.labelTextColor = .whiteColor()

      return chart.drawImage()
   }
}

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
         self.chartView.setImage(self.training.chartImageWithSize(self.contentFrame.size))
         self.chartView.setHidden(false)
      }

      self.didActivateBefore = true
   }

   override func didDeactivate() {
      // This method is called when watch view controller is no longer visible
      super.didDeactivate()
   }

}
