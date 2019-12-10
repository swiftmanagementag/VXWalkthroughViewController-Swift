@version = "1.1.19"

Pod::Spec.new do |s|
  s.name         	= 'VXWalkthroughViewController-Swift'
  s.version      	= @version
  s.summary     	= 'A simple display of walkthroughs in apps.'
  s.homepage 	   	= 'https://github.com/swiftmanagementag/VXWalkthroughViewController-Swift'
  s.license			= { :type => 'MIT', :file => 'LICENSE' }
  s.author       	= { 'Graham Lancashire' => 'lancashire@swift.ch' }
  s.source       	= { :git => 'https://github.com/swiftmanagementag/VXWalkthroughViewController-Swift.git', :tag => s.version.to_s }
  s.platform     	= :ios, '11.0'
  s.source_files 	= 'VXWalkthroughViewController/**/*.swift'
  s.resources 		= 'VXWalkthroughViewController/**/*.{bundle,xib,png,lproj,storyboard}'
  s.resource_bundles = {
    'VXWalkthroughViewController' => ['VXWalkthroughViewController/**/*.{bundle,xib,png,lproj,storyboard}']
  }
  s.requires_arc 	= true
  s.framework		= 'QuartzCore'
  s.dependency    'QRCodeReader.swift', '~> 10.1.0'
end
