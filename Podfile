xcodeproj 'SportAssistant.xcodeproj'
platform :ios, '9.1'

use_frameworks!

def shared_pods
end

target 'SportAssistant' do
   shared_pods
   pod 'Charts'
   pod 'RealmSwift'
   pod 'SwiftyTimer'
   pod 'SwiftDate'
   pod 'ReactiveCocoa', '4.0.0-RC.1'
end

#target 'SportAssistant WatchKit Extension' do
#   platform :watchos, '2.0'
#   shared_pods
#end

link_with 'SportAssistant'