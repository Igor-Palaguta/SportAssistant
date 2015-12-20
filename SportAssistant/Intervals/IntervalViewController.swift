import UIKit
import Charts
import RealmSwift
import ReactiveCocoa

private extension LineChartDataSet {
   convenience init(yVals: [ChartDataEntry], label: String, color: UIColor) {
      self.init(yVals: yVals, label: label)
      self.setColor(color)
      self.setCircleColor(color)
   }
}

final class IntervalViewController: UIViewController {

   var interval: Interval!

   @IBOutlet private weak var chartView: LineChartView!

   override func viewDidLoad() {
      super.viewDidLoad()

      self.chartView.descriptionText = ""
      self.chartView.noDataTextDescription = "You need to provide data for the chart."

      self.chartView.drawBordersEnabled = true

      self.chartView.leftAxis.drawAxisLineEnabled = false
      self.chartView.leftAxis.drawGridLinesEnabled = false
      self.chartView.rightAxis.drawAxisLineEnabled = false
      self.chartView.rightAxis.drawGridLinesEnabled = false
      self.chartView.xAxis.drawAxisLineEnabled = false
      self.chartView.xAxis.drawGridLinesEnabled = false

      self.chartView.drawGridBackgroundEnabled = false
      self.chartView.dragEnabled = true
      self.chartView.setScaleEnabled(true)
      self.chartView.pinchZoomEnabled = false

      self.chartView.legend.position = .BelowChartCenter

      self.addData()

      NSNotificationCenter.defaultCenter()
         .rac_addObserverForName(DidChangeIntervalNotification, object: nil)
         .takeUntil(self.rac_willDeallocSignal())
         .toSignalProducer()
         .startWithNext {
            [weak self] next in
            if let strongSelf = self,
               note = next as? NSNotification,
               id = note.userInfo?["id"] as? String where strongSelf.interval.id == id,
               let data = note.userInfo?["data"] as? AccelerationData {
                  if let chartData = strongSelf.chartView.data as? LineChartData {
                     let xDataSet = chartData.dataSets[0] as! LineChartDataSet
                     let newIndex = xDataSet.valueCount
                     xDataSet.addEntry(ChartDataEntry(value: data.x, xIndex: newIndex))

                     let yDataSet = chartData.dataSets[1] as! LineChartDataSet
                     yDataSet.addEntry(ChartDataEntry(value: data.y, xIndex: newIndex))

                     let zDataSet = chartData.dataSets[2] as! LineChartDataSet
                     zDataSet.addEntry(ChartDataEntry(value: data.z, xIndex: newIndex))

                     chartData.addXValue("\(newIndex)")
                     strongSelf.chartView.notifyDataSetChanged()
                  } else {
                     strongSelf.addAccelerations([data])
                  }
            }
      }
   }

   private func addData() {
      let accelerations = self.interval.data
      if !accelerations.isEmpty {
         self.addAccelerations(accelerations)
      }
   }

   private func addAccelerations<Accelerations: SequenceType where Accelerations.Generator.Element == AccelerationData>(accelerations: Accelerations) {
      var xs: [ChartDataEntry] = []
      var ys: [ChartDataEntry] = []
      var zs: [ChartDataEntry] = []
      var xVals: [String] = []
      for (i, data) in accelerations.enumerate() {
         xs.append(ChartDataEntry(value: data.x, xIndex: i))
         ys.append(ChartDataEntry(value: data.y, xIndex: i))
         zs.append(ChartDataEntry(value: data.z, xIndex: i))
         xVals.append("\(i)")
      }

      let xDataSet = LineChartDataSet(yVals: xs,
         label: "x",
         color: ChartColorTemplates.colorful()[0])
      let yDataSet = LineChartDataSet(yVals: ys,
         label: "y",
         color: ChartColorTemplates.colorful()[1])
      let zDataSet = LineChartDataSet(yVals: zs,
         label: "z",
         color: ChartColorTemplates.colorful()[2])

      let chartData = LineChartData(xVals: xVals, dataSets: [xDataSet, yDataSet, zDataSet])
      self.chartView.data = chartData
   }
}
