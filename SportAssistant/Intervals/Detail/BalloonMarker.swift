import Foundation
import UIKit
import Charts

class BalloonMarker: ChartMarker {
   private let color: UIColor
   private let font: UIFont
   private let insets: UIEdgeInsets

   private let arrowSize = CGSize(width: 15, height: 11)
   private let minimumSize = CGSize(width: 80, height: 40)

   private var attributedText: NSAttributedString?
   private var balloonSize = CGSize.zero

   init(color: UIColor,
      font: UIFont,
      insets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8)) {
         self.color = color
         self.font = font
         self.insets = insets
         super.init()
   }

   override var size: CGSize {
      return self.balloonSize
   }

   override func draw(context context: CGContext, point: CGPoint) {
      guard let attributedText = self.attributedText else {
         return
      }

      let balloonRect = CGRect(origin: point, size: self.balloonSize)
         .offsetBy(dx: -self.balloonSize.width / 2.0, dy: -self.balloonSize.height)

      CGContextSaveGState(context)

      CGContextSetFillColorWithColor(context, self.color.CGColor)
      CGContextBeginPath(context)
      CGContextMoveToPoint(context,
         balloonRect.origin.x,
         balloonRect.origin.y)
      CGContextAddLineToPoint(context,
         balloonRect.origin.x + balloonRect.size.width,
         balloonRect.origin.y)
      CGContextAddLineToPoint(context,
         balloonRect.origin.x + balloonRect.size.width,
         balloonRect.origin.y + balloonRect.size.height - arrowSize.height)
      CGContextAddLineToPoint(context,
         balloonRect.origin.x + (balloonRect.size.width + arrowSize.width) / 2.0,
         balloonRect.origin.y + balloonRect.size.height - arrowSize.height)
      CGContextAddLineToPoint(context,
         balloonRect.origin.x + balloonRect.size.width / 2.0,
         balloonRect.origin.y + balloonRect.size.height)
      CGContextAddLineToPoint(context,
         balloonRect.origin.x + (balloonRect.size.width - arrowSize.width) / 2.0,
         balloonRect.origin.y + balloonRect.size.height - arrowSize.height)
      CGContextAddLineToPoint(context,
         balloonRect.origin.x,
         balloonRect.origin.y + balloonRect.size.height - arrowSize.height)
      CGContextAddLineToPoint(context,
         balloonRect.origin.x,
         balloonRect.origin.y)
      CGContextFillPath(context)

      UIGraphicsPushContext(context)

      attributedText.drawInRect(UIEdgeInsetsInsetRect(balloonRect, self.insets))

      UIGraphicsPopContext()

      CGContextRestoreGState(context)
   }

   override func refreshContent(entry entry: ChartDataEntry, highlight: ChartHighlight) {
      var textLines = [NSNumberFormatter.stringForAcceleration(entry.value)]
      if let data = entry.data as? AccelerationData, activity = data.activity {
         textLines.insert(activity.name, atIndex: 0)
      }
      let text = textLines.joinWithSeparator("\n")
      let attributedText = NSAttributedString(string: text, attributes: [NSFontAttributeName: self.font])
      let textSize = attributedText.size()
      self.attributedText = attributedText
      var balloonSize = textSize
      balloonSize.width = max(self.minimumSize.width, balloonSize.width + self.insets.left + self.insets.right)
      balloonSize.height = max(self.minimumSize.height, balloonSize.height + self.insets.top + self.insets.bottom)
      self.balloonSize = balloonSize
   }
}