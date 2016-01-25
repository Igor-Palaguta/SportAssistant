import WatchKit
import watchOSEngine

class TagController: NSObject {
   @IBOutlet private(set) weak var nameLabel: WKInterfaceLabel!
   @IBOutlet private(set) weak var bestLabel: WKInterfaceLabel!
   @IBOutlet private(set) weak var dateLabel: WKInterfaceLabel!

   private static let dateFormatter: NSDateFormatter = {
      let dateFormatter = NSDateFormatter()
      dateFormatter.dateStyle = .ShortStyle
      dateFormatter.timeStyle = .ShortStyle
      return dateFormatter
   }()

   var trainingTag: Tag! {
      didSet {
         self.nameLabel.setText(self.trainingTag.name)
         let lastStrings = self.trainingTag.last.map {
            tr(.LastFormat(TagController.dateFormatter.stringFromDate($0.start)))
         }

         self.dateLabel.setText(lastStrings)

         let bestString: String? = self.trainingTag.best != 0
            ? tr(.BestFormat(self.trainingTag.best.formattedAcceleration()))
            : nil

         self.bestLabel.setText(bestString)
      }
   }
}
