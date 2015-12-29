import UIKit
import Charts
import RealmSwift
import ReactiveCocoa

private func colorAtIndex(index: Int) -> UIColor {
   let colors = ChartColorTemplates.joyful()
   if index < colors.count {
      return colors[index]
   }
   return ChartColorTemplates.colorful()[index - colors.count]
}

private enum Attributes {
   case Line(UIColor, Bool, CGFloat)
   case Bar(UIColor)

   func dataEntryForValue(value: Double, atIndex index: Int, context: AnyObject?) -> ChartDataEntry {
      switch self {
      case Line(_):
         return ChartDataEntry(value: value, xIndex: index, data: context)
      case Bar(_):
         return BarChartDataEntry(value: value, xIndex: index, data: context)
      }
   }
}

private enum DataExtractor {
   case Field(AccelerationDataField)
   case Activity(TableTennisMotion)
   case AnyActivity

   func valueForData(data: AccelerationData) -> Double? {
      switch self {
      case .Field(let id):
         return data[id]
      case .Activity(let motion):
         if let activity = data.activity where activity.name == motion.description {
            return data.total
         }
         return nil
      case .AnyActivity:
         if data.activity != nil {
            return data.total
         }
         return nil
      }
   }

   var label: String {
      switch self {
      case .Field(let id):
         return id.rawValue
      case .Activity(let motion):
         return motion.description
      case .AnyActivity:
         return "Activity"
      }
   }
}

private class IntervalDataSet {

   private var initialDataEntries: [ChartDataEntry] = []
   private let data: DataExtractor
   private let attributes: Attributes

   private var _chartDataSet: ChartDataSet?
   private var chartDataSet: ChartDataSet {
      if let chartDataSet = _chartDataSet {
         return chartDataSet
      }

      let chartDataSet: ChartDataSet
      switch self.attributes {
      case .Bar(let color):
         print(self.initialDataEntries)
         let barDataSet = BarChartDataSet(yVals: self.initialDataEntries,
            label: self.data.label)
         print(barDataSet.yVals)
         barDataSet.barShadowColor = .clearColor()
         barDataSet.setColor(color)
         chartDataSet = barDataSet
      case .Line(let color, let cubicEnabled, let width):
         let lineDataSet = LineChartDataSet(yVals: self.initialDataEntries,
            label: self.data.label)
         lineDataSet.setColor(color)
         lineDataSet.setCircleColor(color)
         lineDataSet.drawCubicEnabled = cubicEnabled
         lineDataSet.lineWidth = width
         lineDataSet.drawCirclesEnabled = false
         lineDataSet.drawValuesEnabled = false
         chartDataSet = lineDataSet
      }

      _chartDataSet = chartDataSet
      return chartDataSet
   }

   private lazy var barChartDataSet: BarChartDataSet? = {
      [unowned self] in
      return self.chartDataSet as? BarChartDataSet
   }()

   private lazy var lineChartDataSet: LineChartDataSet? = {
      [unowned self] in
      return self.chartDataSet as? LineChartDataSet
      }()

   init(data: DataExtractor, attributes: Attributes) {
      self.data = data
      self.attributes = attributes
   }

   func dataEntryForData(data: AccelerationData, atIndex index: Int) -> ChartDataEntry? {
      if let value = self.data.valueForData(data) {
         return self.attributes.dataEntryForValue(value, atIndex: index, context: data)
      }
      return nil
   }

   func addData(data: AccelerationData, atIndex index: Int) {
      if let dataEntry = self.dataEntryForData(data, atIndex: index) {
         if let chartDataSet = self._chartDataSet {
            chartDataSet.addEntry(dataEntry)
         } else {
            self.initialDataEntries.append(dataEntry)
         }
      }
   }
}

private struct IntervalDataSource {

   private let dataSets: [IntervalDataSet] = [/*IntervalDataSet(data: .Field(.x), attributes: .Line(colorAtIndex(0), false, 1)),
      IntervalDataSet(data: .Field(.y), attributes: .Line(colorAtIndex(1), false, 1)),
      IntervalDataSet(data: .Field(.z), attributes: .Line(colorAtIndex(2), false, 1)),*/
      IntervalDataSet(data: .Field(.total), attributes: .Line(colorAtIndex(3), true, 2)),
      IntervalDataSet(data: .AnyActivity, attributes: .Bar(colorAtIndex(0)))
      /*IntervalDataSet(data: .Activity(.RightTopSpin(.Right)), attributes: .Bar(colorAtIndex(4))),
      IntervalDataSet(data: .Activity(.LeftTopSpin(.Right)), attributes: .Bar(colorAtIndex(5))),
      IntervalDataSet(data: .Activity(.RightTopSpin(.Left)), attributes: .Bar(colorAtIndex(6))),
      IntervalDataSet(data: .Activity(.LeftTopSpin(.Left)), attributes: .Bar(colorAtIndex(7))),
      IntervalDataSet(data: .Activity(.Unknown), attributes: .Bar(.grayColor()))*/
   ]

   private let chartData: ChartData

   init(interval: Interval) {

      let startDate = interval.data.first!.date
      let xVals = interval.data.map {
         data -> String in
         let timestamp = data.date.timeIntervalSinceDate(startDate)
         return timestamp.toDurationString()
      }

      for (i, data) in interval.data.enumerate() {
         self.dataSets.forEach {
            dataSet in
            dataSet.addData(data, atIndex: i)
         }
      }

      let lineData = LineChartData()
      lineData.dataSets = self.dataSets.flatMap { $0.lineChartDataSet }

      let barData = BarChartData()
      barData.dataSets = self.dataSets.flatMap { $0.barChartDataSet }

      let allData = CombinedChartData(xVals: xVals)
      allData.lineData = lineData
      allData.barData = barData
      
      self.chartData = allData
   }

   func addNewDataFromInterval(interval: Interval) {
      let previousCount = self.chartData.xValCount

      let newData = interval.data[previousCount..<interval.currentCount]
      let startDate = interval.data.first!.date

      for (i, data) in newData.enumerate() {
         self.dataSets.forEach {
            dataSet in
            if let dataEntry = dataSet.dataEntryForData(data, atIndex: previousCount + i) {
               dataSet.chartDataSet.addEntry(dataEntry)
            }
         }

         let timestamp = data.date.timeIntervalSinceDate(startDate)
         self.chartData.addXValue(timestamp.toDurationString())
      }
   }
}

final class IntervalViewController: UIViewController {

   var interval: Interval! {
      didSet {
         self.history = self.interval?.history
      }
   }

   @IBOutlet private weak var chartView: CombinedChartView!

   private var history: History!
   private var dataSource: IntervalDataSource?

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

      self.chartView.drawOrder = [CombinedChartDrawOrder.Bar.rawValue, CombinedChartDrawOrder.Line.rawValue]

      self.chartView.legend.position = .BelowChartCenter

      let best = self.interval.history.best

      let bestLine = ChartLimitLine(limit: best, label: tr(.AccelerationRecord))

      bestLine.lineWidth = 4
      bestLine.lineDashLengths = [5, 5]
      bestLine.labelPosition = .RightTop

      self.chartView.leftAxis.addLimitLine(bestLine)
      self.chartView.leftAxis.customAxisMax = best * 1.1
      self.chartView.rightAxis.customAxisMax = best * 1.1

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
               strongSelf.chartView.rightAxis.customAxisMax = best * 1.1
               strongSelf.chartView.notifyDataSetChanged()
            }
      }

      DynamicProperty(object: self, keyPath: "title") <~
         DynamicProperty(object: self.interval, keyPath: "best")
            .producer
            .takeUntil(self.rac_willDeallocSignalProducer())
            .map { $0 as! Double }
            .skipRepeats()
            .map { NSNumberFormatter.stringForAcceleration($0) }

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

            if let dataSource = strongSelf.dataSource {
               dataSource.addNewDataFromInterval(strongSelf.interval)
               strongSelf.chartView.notifyDataSetChanged()
            } else {
               strongSelf.addData()
            }
      }
   }

   private func addData() {
      if !self.interval.data.isEmpty {
         let dataSource = IntervalDataSource(interval: self.interval)
         self.chartView.data = dataSource.chartData
         self.dataSource = dataSource
      }
   }
}
