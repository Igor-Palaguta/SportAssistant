import WatchKit

extension NSProcessInfo  {
   var isSimulator: Bool {
      return self.environment["SIMULATOR_MODEL_IDENTIFIER"] != nil
   }
}
