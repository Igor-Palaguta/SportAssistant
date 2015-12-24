xcodeproj 'SportAssistant.xcodeproj'

use_frameworks!

def shared_pods
   pod 'RealmSwift'
end

target 'SportAssistant' do
   platform :ios, '9.1'
   shared_pods
   pod 'Charts'
   pod 'SwiftyTimer'
   pod 'SwiftDate'
   pod 'ReactiveCocoa', '4.0.0-RC.1'
end

target 'SportAssistant WatchKit Extension' do
   platform :watchos, '2.0'
   shared_pods
end

link_with 'SportAssistant'