Pod::Spec.new do |s|
  s.name         = "OpenLocate"
  s.version      = "1.4.0"
  s.summary      = "OpenLocate is an open source Android and iOS SDK for mobile location collection."
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = "OpenLocate"
  s.homepage     = 'https://github.com/OpenLocate/openlocate-ios'
  s.source = { :git => 'https://github.com/OpenLocate/openlocate-ios.git', :tag => s.version }
  
  s.ios.deployment_target = '8.0'
  
  s.source_files = 'Source/*.swift'
  s.framework    = "CoreLocation"
end
