platform :ios, '8.0'
use_frameworks!

Example = 'Example/iOS Example.xcodeproj'
OpenLocate = 'OpenLocate.xcodeproj'

workspace 'OpenLocate'
project Example

def fabric_pods
  pod 'Fabric'
  pod 'Crashlytics'
end
 
target 'iOS Example' do
  project Example
  fabric_pods
  pod 'SwiftLint'
  pod 'Alamofire'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.0'
        end
    end
end
