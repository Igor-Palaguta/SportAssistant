import UIKit
import Charts
import ReactiveCocoa

private enum Attributes {
   case Line(UIColor, Bool, CGFloat)
   case Point(UIColor, Bool)
   case Bar(UIColor)
   case Bubble

   func dataEntryForValue(value: Double, atIndex index: Int, data: AccelerationData) -> ChartDataEntry {
      switch self {
      case Line(_), Point(_):
         return ChartDataEntry(value: value, xIndex: index, data: data)
      case Bar(_):
         return BarChartDataEntry(value: value, xIndex: index, data: data)
      case Bubble:
         return BubbleChartDataEntry(xIndex: index, value: value, size: 3, data: data)
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

   var label: String? {
      switch self {
      case .Field(let id):
         return id.rawValue
      case .Activity(let motion):
         return motion.description
      case .AnyActivity:
         return nil
      }
   }
}

private extension LineChartDataSet {
   convenience init(yVals: [ChartDataEntry]?, label: String?, color: UIColor, points: Bool = false) {
      self.init(yVals: yVals, label: label)
      let lineColor = points ? color.colorWithAlphaComponent(0) : color
      self.setColor(lineColor)
      self.setCircleColor(color)
      self.drawCirclesEnabled = points
      self.drawValuesEnabled = points
      self.highlightEnabled = points
   }
}

private extension BarLineChartViewBase {
   var yMin: Double? {
      set {
         if let yMin = newValue {
            self.leftAxis.customAxisMin = yMin
            self.rightAxis.customAxisMin = yMin
         } else {
            self.leftAxis.resetCustomAxisMin()
            self.rightAxis.resetCustomAxisMin()
         }
      }
      get {
         return self.leftAxis.customAxisMin
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
         let barDataSet = BarChartDataSet(yVals: self.initialDataEntries,
            label: self.data.label)
         barDataSet.barShadowColor = .clearColor()
         barDataSet.setColor(color)
         chartDataSet = barDataSet
      case .Line(let color, let cubicEnabled, let width):
         let lineDataSet = LineChartDataSet(yVals: self.initialDataEntries,
            label: self.data.label, color: color)
         lineDataSet.drawCubicEnabled = cubicEnabled
         lineDataSet.lineWidth = width
         chartDataSet = lineDataSet
      case .Point(let color, let cubicEnabled):
         let lineDataSet = LineChartDataSet(yVals: self.initialDataEntries,
            label: self.data.label, color: color, points: true)
         lineDataSet.drawCubicEnabled = cubicEnabled
         chartDataSet = lineDataSet
      case .Bubble:
         let bubbleDataSet = BubbleChartDataSet(yVals: self.initialDataEntries,
            label: self.data.label)
         bubbleDataSet.colors = [.redColor()]
         chartDataSet = bubbleDataSet
      }

      _chartDataSet = chartDataSet
      return chartDataSet
   }

   init(data: DataExtractor, attributes: Attributes) {
      self.data = data
      self.attributes = attributes
   }

   func dataEntryForData(data: AccelerationData, atIndex index: Int) -> ChartDataEntry? {
      if let value = self.data.valueForData(data) {
         return self.attributes.dataEntryForValue(value, atIndex: index, data: data)
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

   private let dataSets: [IntervalDataSet] =
   [IntervalDataSet(data: .Field(.x), attributes: .Line(ChartColorTemplates.joyful()[0], false, 1)),
      IntervalDataSet(data: .Field(.y), attributes: .Line(ChartColorTemplates.joyful()[1], false, 1)),
      IntervalDataSet(data: .Field(.z), attributes: .Line(ChartColorTemplates.joyful()[2], false, 1)),
      IntervalDataSet(data: .Field(.total), attributes: .Line(ChartColorTemplates.joyful()[3], true, 2)),
      IntervalDataSet(data: .AnyActivity, attributes: .Point(ChartColorTemplates.joyful()[4], true))
   ]

   private let chartData: ChartData

   init(interval: Interval) {

      let xVals = interval.data.map {
         return $0.timestamp.toDurationString()
      }

      for (i, data) in interval.data.enumerate() {
         self.dataSets.forEach {
            dataSet in
            dataSet.addData(data, atIndex: i)
         }
      }

      let lineData = LineChartData(xVals: xVals)
      lineData.dataSets = self.dataSets.flatMap { $0.chartDataSet as? LineChartDataSet }

      let barData = BarChartData(xVals: xVals)
      barData.dataSets = self.dataSets.flatMap { $0.chartDataSet as? BarChartDataSet }

      let bubbleData = BubbleChartData(xVals: xVals)
      bubbleData.dataSets = self.dataSets.flatMap { $0.chartDataSet as? BubbleChartDataSet }

      let allData = CombinedChartData(xVals: xVals)
      allData.lineData = lineData
      //allData.barData = barData
      allData.bubbleData = bubbleData
      
      self.chartData = allData
   }

   func addNewData<T: SequenceType where T.Generator.Element == AccelerationData>(newData: T) {
      let previousCount = self.chartData.xValCount

      for (i, data) in newData.enumerate() {
         self.dataSets.forEach {
            dataSet in
            if let dataEntry = dataSet.dataEntryForData(data, atIndex: previousCount + i) {
               dataSet.chartDataSet.addEntry(dataEntry)
            }
         }

         self.chartData.addXValue(data.timestamp.toDurationString())
      }
   }

   func setXYZVisible(visible: Bool) {
      for dataSet in self.dataSets {
         switch dataSet.data {
         case .Field(.x), .Field(.y), .Field(.z):
            dataSet.chartDataSet.visible = visible
         default:
            continue
         }
      }
   }
}

final class IntervalViewController: UIViewController {

   var interval: Interval!

   @IBOutlet private weak var chartView: CombinedChartView!
   @IBOutlet private weak var tableView: UITableView!
   @IBOutlet private weak var visibleTableConstraint: NSLayoutConstraint!

   //!Out of hierarchy
   @IBOutlet private var filterControl: UISegmentedControl!
   @IBOutlet private var dataHeaderView: UIView!

   private lazy var historyController = HistoryController()
   private var dataSource: IntervalDataSource?


   private enum Filter: Int {
      case Activities
      case All

      func filterData<T: SequenceType where T.Generator.Element == AccelerationData>(data: T) -> [AccelerationData] {
         switch self {
         case .Activities:
            return data.filter { $0.activity != nil }
         case .All:
            return Array(data)
         }
      }
   }

   private func differenceForOldData(oldData: [AccelerationData], newData: [AccelerationData]) -> (inserted: [NSIndexPath], deleted: [NSIndexPath]) {

      if oldData.count == newData.count {
         return (inserted: [], deleted: [])
      }

      let (all, activities) = oldData.count > newData.count
         ? (oldData, newData)
         : (newData, oldData)

      var currentIndex = 0
      let indexPaths: [NSIndexPath] = all.flatMap {
         data in

         defer {
            currentIndex += 1
         }

         if activities.contains({$0 == data}) {
            return nil
         }

         return NSIndexPath(forRow: currentIndex, inSection: 0)
      }

      if oldData.count > newData.count {
         return (inserted: [], deleted: indexPaths)
      } else {
         return (inserted: indexPaths, deleted: [])
      }
   }

   private var filter: Filter = .Activities {
      didSet {
         let showAll = self.filter == .All
         self.dataSource?.setXYZVisible(showAll)
         self.chartView.yMin = showAll ? nil : 0

         self.chartView.notifyDataSetChanged()

         //let oldData = self.data
         self.data = self.filter.filterData(self.interval.data)
         self.tableView.contentOffset = .zero
         self.tableView.reloadData()

         /*let (inserted, deleted) = self.differenceForOldData(oldData, newData: self.data)
         if inserted.isEmpty && deleted.isEmpty {
            return
         }

         self.tableView.beginUpdates()

         if !inserted.isEmpty {
            self.tableView.insertRowsAtIndexPaths(inserted, withRowAnimation: .Fade)
         }

         if !deleted.isEmpty {
            self.tableView.deleteRowsAtIndexPaths(deleted, withRowAnimation: .Fade)
         }

         self.tableView.endUpdates()*/
      }
   }

   private var data: [AccelerationData] = []

   override func viewDidLoad() {
      super.viewDidLoad()

      self.automaticallyAdjustsScrollViewInsets = false

      self.tableView.estimatedRowHeight = 40
      self.tableView.rowHeight = UITableViewAutomaticDimension

      self.chartView.delegate = self

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

      self.chartView.drawOrder = [CombinedChartDrawOrder.Bar.rawValue, CombinedChartDrawOrder.Line.rawValue, CombinedChartDrawOrder.Bubble.rawValue]

      self.chartView.legend.position = .BelowChartCenter

      let best = self.historyController.best

      let bestLine = ChartLimitLine(limit: best, label: tr(.AccelerationRecord))

      bestLine.lineWidth = 4
      bestLine.lineDashLengths = [5, 5]
      bestLine.labelPosition = .RightTop

      self.chartView.leftAxis.addLimitLine(bestLine)
      self.chartView.leftAxis.customAxisMax = best * 1.1
      self.chartView.rightAxis.customAxisMax = best * 1.1

      self.chartView.marker = BalloonMarker(color: .lightGrayColor(), font: UIFont.systemFontOfSize(12))

      DynamicProperty(object: self.historyController, keyPath: "best")
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
         .filter { $0 != 0 }
         .skipRepeats()
         .takeUntil(self.rac_willDeallocSignalProducer())
         .startWithNext {
            [weak self] count in
            guard let strongSelf = self else {
               return
            }

            if let dataSource = strongSelf.dataSource {
               let previousCount = strongSelf.chartView.data!.xValCount
               let newData = strongSelf.interval.data[previousCount..<count]

               dataSource.addNewData(newData)
               strongSelf.chartView.notifyDataSetChanged()

               let filteredData = strongSelf.filter.filterData(newData)
               if !filteredData.isEmpty {
                  strongSelf.data.appendContentsOf(filteredData)
                  strongSelf.tableView.reloadData()
               }
            } else {
               let dataSource = IntervalDataSource(interval: strongSelf.interval)
               strongSelf.dataSource = dataSource

               dataSource.setXYZVisible(strongSelf.filter == .All)
               strongSelf.chartView.yMin = strongSelf.filter == .All ? nil : 0
               strongSelf.chartView.data = dataSource.chartData

               strongSelf.data = strongSelf.filter.filterData(strongSelf.interval.data)
               strongSelf.tableView.reloadData()
            }
      }

      self.navigationItem.titleView = self.filterControl
   }

   override func shouldAutorotate() -> Bool {
      return true
   }

   override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
      return [.Portrait, .Landscape]
   }

   override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
      self.navigationController?.setNavigationBarHidden(toInterfaceOrientation.isLandscape, animated: true)

      UIView.animateWithDuration(duration) {
         self.visibleTableConstraint.priority = toInterfaceOrientation.isPortrait ? 750 : 250
         self.view.layoutIfNeeded()
      }
   }

   @IBAction private func changeFilterAction(control: UISegmentedControl) {
      self.filter = Filter(rawValue: control.selectedSegmentIndex)!
   }
}

extension IntervalViewController: UITableViewDataSource, UITableViewDelegate {
   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.data.count
   }

   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      let cell: AccelerationDataCell = tableView.dequeueCellForIndexPath(indexPath)
      let data = self.data[indexPath.row]
      cell.data = data
      return cell
   }

   func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
      return self.dataHeaderView
   }
}

extension IntervalViewController: ChartViewDelegate {
   func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
      if let data = entry.data as? AccelerationData,
         index = self.data.indexOf({$0 == data}) {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0),
               atScrollPosition: .Top,
               animated: true)
      }
   }
}
