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

   var interval: Interval! {
      didSet {
         self.history = self.interval?.history
      }
   }

   @IBOutlet private weak var chartView: LineChartView!

   private var history: History!

   override func viewDidLoad() {
      super.viewDidLoad()

      self.chartView.descriptionText = tr(.AccelerationData)
      self.chartView.noDataTextDescription = tr(.AccelerationDataEmpty)

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
      self.chartView.autoScaleMinMaxEnabled = true

      self.chartView.legend.position = .BelowChartCenter

      let best = self.interval.history.best

      let bestLine = ChartLimitLine(limit: best, label: tr(.AccelerationRecord))

      bestLine.lineWidth = 4
      bestLine.lineDashLengths = [5, 5]
      bestLine.labelPosition = .RightTop

      self.chartView.leftAxis.addLimitLine(bestLine)
      self.chartView.leftAxis.customAxisMax = best * 1.1

      self.addData()

      DynamicProperty(object: self.interval.history, keyPath: "best")
         .producer
         .map { $0 as! Double }
         .skipRepeats()
         .takeUntil(self.rac_willDeallocSignalProducer())
         .startWithNext {
            [weak self] best in
            if let strongSelf = self {
               bestLine.limit = best
               strongSelf.chartView.leftAxis.customAxisMax = best * 1.1
               strongSelf.chartView.notifyDataSetChanged()
            }
      }

      DynamicProperty(object: self, keyPath: "title") <~
         DynamicProperty(object: self.interval, keyPath: "best")
            .producer
            .takeUntil(self.rac_willDeallocSignalProducer())
            .map { $0 as! Double }
            .skipRepeats()
            .map { NSNumberFormatter.formatAccelereration($0) }

      DynamicProperty(object: self.interval, keyPath: "currentCount")
         .producer
         .map { $0 as! Int }
         .skip(1)
         .skipRepeats()
         .takeUntil(self.rac_willDeallocSignalProducer())
         .startWithNext {
            [weak self] count in
            guard let strongSelf = self else {
               return
            }

            if let chartData = strongSelf.chartView.lineData {
               let xDataSet = chartData.dataSets[0] as! LineChartDataSet
               let previousCount = xDataSet.valueCount

               let newData = strongSelf.interval.data[previousCount..<count]

               for (i, data) in newData.enumerate() {
                  let newIndex = previousCount + i
                  xDataSet.addEntry(ChartDataEntry(value: data.x, xIndex: newIndex))

                  let yDataSet = chartData.dataSets[1] as! LineChartDataSet
                  yDataSet.addEntry(ChartDataEntry(value: data.y, xIndex: newIndex))

                  let zDataSet = chartData.dataSets[2] as! LineChartDataSet
                  zDataSet.addEntry(ChartDataEntry(value: data.z, xIndex: newIndex))

                  let totalDataSet = chartData.dataSets[3] as! LineChartDataSet
                  totalDataSet.addEntry(ChartDataEntry(value: data.total, xIndex: newIndex))
                  
                  chartData.addXValue("\(newIndex)")
               }

               strongSelf.chartView.notifyDataSetChanged()
            } else {
               strongSelf.addData()
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
      var totals: [ChartDataEntry] = []

      var xVals: [String] = []

      for (i, data) in accelerations.enumerate() {
         xs.append(ChartDataEntry(value: data.x, xIndex: i))
         ys.append(ChartDataEntry(value: data.y, xIndex: i))
         zs.append(ChartDataEntry(value: data.z, xIndex: i))
         totals.append(ChartDataEntry(value: data.total, xIndex: i))
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

      let totalDataSet = LineChartDataSet(yVals: totals,
         label: "acceleration",
         color: ChartColorTemplates.colorful()[3])
      totalDataSet.lineWidth = 2

      let chartData = LineChartData(xVals: xVals, dataSets: [xDataSet, yDataSet, zDataSet, totalDataSet])
      self.chartView.data = chartData
   }
}
