@version = "1.1.24"

Pod::Spec.new do |s|
  s.name         	= 'VXWalkthroughViewController-Swift'
  s.version      	= @version
  s.summary     	= 'A simple display of walkthroughs in apps.'
  s.homepage 	   	= 'https://github.com/swiftmanagementag/VXWalkthroughViewController-Swift'
  s.license			= { :type => 'MIT', :file => 'LICENSE' }
  s.author       	= { 'Graham Lancashire' => 'lancashire@swift.ch' }
  s.source       	= { :git => 'https://github.com/swiftmanagementag/VXWalkthroughViewController-Swift.git', :tag => s.version.to_s }
  s.platform     	= :ios, '14.0'
  s.swift_version   = '5.0'
  s.module_name   = 'VXWalkthrough'
  s.source_files 	= 'Sources/**/*.swift'
  s.resources 		= 'Sources/**/*.{bundle,xib,lproj,storyboard,png}'
  #s.resource_bundles = {
  #  'VXWalkthroughViewController' => ['VXWalkthroughViewController/**/*.{bundle,xib,png,lproj,storyboard}']
  #}
  s.requires_arc 	= true
  s.framework		= 'QuartzCore'
  s.dependency    'QRCodeReader.swift', '~> 10.1.0'
end
