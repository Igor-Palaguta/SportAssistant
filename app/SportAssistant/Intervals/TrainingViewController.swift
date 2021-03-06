import UIKit
import MessageUI
import Charts
import ReactiveCocoa
import iOSEngine

private enum Attributes {
   case Line(UIColor, Bool, CGFloat)
   case Point(UIColor, Bool)
   case Bar(UIColor)
   case Bubble

   func dataEntryForValue(value: Double, atIndex index: Int, event: AccelerationEvent) -> ChartDataEntry {
      switch self {
      case Line(_), Point(_):
         return ChartDataEntry(value: value, xIndex: index, data: event)
      case Bar(_):
         return BarChartDataEntry(value: value, xIndex: index, data: event)
      case Bubble:
         return BubbleChartDataEntry(xIndex: index, value: value, size: 3, data: event)
      }
   }
}

private enum DataExtractor {
   case Field(AccelerationEventField)
   case AnyActivity

   func valueForEvent(event: AccelerationEvent) -> Double? {
      switch self {
      case .Field(let id):
         return event[id]
      case .AnyActivity:
         if event.activity != nil {
            return event.total
         }
         return nil
      }
   }

   var label: String? {
      switch self {
      case .Field(let id):
         return id.rawValue
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

private class TrainingDataSet {

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

   func dataEntryForEvent(event: AccelerationEvent, atIndex index: Int) -> ChartDataEntry? {
      if let value = self.data.valueForEvent(event) {
         return self.attributes.dataEntryForValue(value, atIndex: index, event: event)
      }
      return nil
   }

   func addEvent(event: AccelerationEvent, atIndex index: Int) {
      if let dataEntry = self.dataEntryForEvent(event, atIndex: index) {
         if let chartDataSet = self._chartDataSet {
            chartDataSet.addEntry(dataEntry)
         } else {
            self.initialDataEntries.append(dataEntry)
         }
      }
   }
}

private struct TrainingDataSource {

   private let dataSets: [TrainingDataSet] =
   [TrainingDataSet(data: .Field(.x), attributes: .Line(ChartColorTemplates.joyful()[0], false, 1)),
      TrainingDataSet(data: .Field(.y), attributes: .Line(ChartColorTemplates.joyful()[1], false, 1)),
      TrainingDataSet(data: .Field(.z), attributes: .Line(ChartColorTemplates.joyful()[2], false, 1)),
      TrainingDataSet(data: .Field(.total), attributes: .Line(ChartColorTemplates.joyful()[3], true, 2)),
      TrainingDataSet(data: .AnyActivity, attributes: .Point(ChartColorTemplates.joyful()[4], true))
   ]

   private let chartData: ChartData

   init(training: Training) {

      let xVals = training.events.map {
         return $0.timestamp.toDurationString()
      }

      for (i, event) in training.events.enumerate() {
         self.dataSets.forEach {
            dataSet in
            dataSet.addEvent(event, atIndex: i)
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

   func addEvents<T: SequenceType where T.Generator.Element == AccelerationEvent>(events: T) {
      let previousCount = self.chartData.xValCount

      for (i, event) in events.enumerate() {
         self.dataSets.forEach {
            dataSet in
            if let dataEntry = dataSet.dataEntryForEvent(event, atIndex: previousCount + i) {
               dataSet.chartDataSet.addEntry(dataEntry)
            }
         }

         self.chartData.addXValue(event.timestamp.toDurationString())
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

final class TrainingViewController: UIViewController {

   var training: Training!

   @IBOutlet private weak var chartView: CombinedChartView!
   @IBOutlet private weak var tableView: UITableView!
   @IBOutlet private weak var emptyLabel: UILabel!
   @IBOutlet private weak var visibleTableConstraint: NSLayoutConstraint!

   //!Out of hierarchy
   @IBOutlet private var filterControl: UISegmentedControl!
   @IBOutlet private var dataHeaderView: UIView!

   private var dataSource: TrainingDataSource?

   private var events: [AccelerationEvent] = [] {
      didSet {
         self.tableView.hidden = self.events.isEmpty
      }
   }

   private enum Filter: Int {
      case Peaks
      case All

      var emptyMessage: String {
         switch self {
         case Peaks:
            return tr(.NoPeaks)
         case All:
            return tr(.AccelerationEventEmpty)
         }
      }

      func filterEvents<T: SequenceType where T.Generator.Element == AccelerationEvent>(events: T) -> [AccelerationEvent] {
         switch self {
         case Peaks:
            return events.filter { $0.activity != nil }
         case All:
            return Array(events)
         }
      }
   }

   private var filter: Filter = .Peaks {
      didSet {
         let showAll = self.filter == .All
         self.dataSource?.setXYZVisible(showAll)
         self.chartView.yMin = showAll ? nil : 0

         self.chartView.notifyDataSetChanged()

         self.events = self.filter.filterEvents(self.training.events)
         self.emptyLabel.text = self.filter.emptyMessage
         self.tableView.contentOffset = .zero
         self.tableView.reloadData()
      }
   }

   override func viewDidLoad() {
      super.viewDidLoad()

      self.automaticallyAdjustsScrollViewInsets = false

      self.tableView.estimatedRowHeight = 40
      self.tableView.rowHeight = UITableViewAutomaticDimension
      self.tableView.hidden = true

      self.chartView.delegate = self

      self.chartView.descriptionText = tr(.AccelerationEvent)
      self.chartView.noDataTextDescription = tr(.AccelerationEventEmpty)

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

      let best = StorageController.UIController.best

      let bestLine = ChartLimitLine(limit: best, label: tr(.AccelerationRecord))

      bestLine.lineWidth = 4
      bestLine.lineDashLengths = [5, 5]
      bestLine.labelPosition = .RightTop

      self.chartView.leftAxis.addLimitLine(bestLine)
      self.chartView.leftAxis.customAxisMax = best * 1.1
      self.chartView.rightAxis.customAxisMax = best * 1.1

      self.chartView.marker = BalloonMarker(color: .lightGrayColor(), font: UIFont.systemFontOfSize(12))

      DynamicProperty(object: StorageController.UIController, keyPath: "best")
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
         DynamicProperty(object: self.training, keyPath: "best")
            .producer
            .takeUntil(self.rac_willDeallocSignalProducer())
            .map { $0 as! Double }
            .skipRepeats()
            .map { $0.formattedAcceleration }

      self.training.events.changeSignal()
         .takeUntil(self.training.invalidateSignal())
         .takeUntil(self.rac_willDeallocSignalProducer())
         .startWithNext {
            [weak self] trainings in
            guard let strongSelf = self else {
               return
            }

            let count = trainings.count
            if let dataSource = strongSelf.dataSource {
               let previousCount = strongSelf.chartView.data!.xValCount
               let newEvents = strongSelf.training.events[previousCount..<count]

               dataSource.addEvents(newEvents)
               strongSelf.chartView.notifyDataSetChanged()

               let filteredEvents = strongSelf.filter.filterEvents(newEvents)
               if !filteredEvents.isEmpty {
                  strongSelf.events.appendContentsOf(filteredEvents)
                  strongSelf.tableView.hidden = false
                  strongSelf.tableView.reloadData()
               }
            } else if count > 0 {
               let dataSource = TrainingDataSource(training: strongSelf.training)
               strongSelf.dataSource = dataSource

               dataSource.setXYZVisible(strongSelf.filter == .All)
               strongSelf.chartView.yMin = strongSelf.filter == .All ? nil : 0
               strongSelf.chartView.data = dataSource.chartData

               strongSelf.events = strongSelf.filter.filterEvents(strongSelf.training.events)
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
         self.visibleTableConstraint.priority = toInterfaceOrientation.isPortrait ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow
         self.view.layoutIfNeeded()
      }
   }

   @IBAction private func changeFilterAction(control: UISegmentedControl) {
      self.filter = Filter(rawValue: control.selectedSegmentIndex)!
   }

   @IBAction private func showOptionsAction(_: UIBarButtonItem) {
      let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

      let emailAction = UIAlertAction(title: tr(.EmailShare), style: .Default) {
         [unowned self] _ in
         guard MFMailComposeViewController.canSendMail() else {
            UIAlertController.presentInController(self, title: nil, message: tr(.CannotSendMail))
            return
         }

         let mailController = MFMailComposeViewController()
         mailController.mailComposeDelegate = self
         mailController.setSubject(self.training.start.toString(.ShortStyle)!)
         let csvLines = self.training.events.map { "\($0.timestamp), \($0.x), \($0.y) \($0.z) \($0.total)" }
         let csv = csvLines.joinWithSeparator("\n")
         mailController.addAttachmentData(csv.dataUsingEncoding(NSUTF8StringEncoding)!,
            mimeType: "text/plain",
            fileName: "training.txt")
         self.presentViewController(mailController, animated: true, completion: nil)
      }

      alert.addAction(emailAction)

      let tagsAction = UIAlertAction(title: tr(.EditTags), style: .Default) {
         [unowned self] _ in
         self.performSegue(StoryboardSegue.Main.EditTags)
      }

      alert.addAction(tagsAction)

      let cancelAction = UIAlertAction(title: tr(.Cancel), style: .Cancel, handler: nil)
      alert.addAction(cancelAction)

      self.presentViewController(alert, animated: true, completion: nil)
   }

   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      if let navigationController = segue.destinationViewController as? UINavigationController,
         let tagsViewController = navigationController.viewControllers.first as? TagsViewController {
            tagsViewController.actions = []
            tagsViewController.mode = .Picker(.Selected(Array(self.training.tags)), [.AllowsEmpty, .AllowsMultipleSelection])
            tagsViewController.editable = false
            tagsViewController.completionHandler = {
               [unowned self] tagsViewController in
               StorageController.UIController.assignTags(tagsViewController.mode.tags,
                  forTraining: self.training)
               ClientSynchronizer.defaultClient.sendTagsOfTraining(self.training)
               tagsViewController.dismissViewControllerAnimated(true, completion: nil)
            }
      }
   }
}

extension TrainingViewController: UITableViewDataSource, UITableViewDelegate {
   func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.events.count
   }

   func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
      let cell: AccelerationEventCell = tableView.dequeueCellForIndexPath(indexPath)
      cell.event = self.events[indexPath.row]
      return cell
   }

   func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
      return self.dataHeaderView
   }
}

extension TrainingViewController: ChartViewDelegate {
   func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
      if let event = entry.data as? AccelerationEvent,
         index = self.events.indexOf({$0 == event}) {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0),
               atScrollPosition: .Top,
               animated: true)
      }
   }
}

extension TrainingViewController: MFMailComposeViewControllerDelegate {
   func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
      if let error = error {
         error.presentInController(self)
      } else {
         controller.dismissViewControllerAnimated(true, completion: nil)
      }
   }
}
