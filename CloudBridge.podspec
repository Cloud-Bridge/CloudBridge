#
# Be sure to run `pod lib lint CloudBridge.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CloudBridge"
  s.version          = "2.3.3"
  s.summary          = "The missing bridge between your data model and various Cloud backends."
  s.homepage         = "https://github.com/OliverLetterer"
  s.license          = 'MIT'
  s.author           = { "Oliver Letterer" => "oliver.letterer@gmail.com" }
  s.source           = { :git => "https://github.com/OliverLetterer/CloudBridge.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/oletterer'

  s.platforms    = { :ios => '9.0', :tvos => '9.0', :watchos => '2.0' }
  s.requires_arc = true

  s.frameworks = 'Foundation'
  s.default_subspec = 'CoreData+REST'

  s.subspec 'CloudBridge' do |ss|
    ss.source_files = 'CloudBridge', 'JSON'
  end

  s.subspec 'CoreData' do |ss|
    ss.source_files = 'CoreData'

    ss.dependency 'CloudBridge/CloudBridge'
  end

  s.subspec 'Realm' do |ss|
    ss.source_files = 'Realm'

    ss.dependency 'Realm', '~> 3.0'
    ss.dependency 'CloudBridge/CloudBridge'
  end

  s.subspec 'CBRRESTConnection' do |ss|
    ss.source_files = 'CBRRESTConnection', 'CBRRESTConnection/JSON'

    ss.dependency 'AFNetworking', '~> 3.0'
    ss.dependency 'CloudBridge/CloudBridge'
  end

  s.subspec 'CoreData+REST' do |ss|
    ss.source_files = 'CBRRESTConnection/CoreData'

    ss.dependency 'CloudBridge/CoreData'
    ss.dependency 'CloudBridge/CBRRESTConnection'
  end

  s.subspec 'Realm+REST' do |ss|
    ss.source_files = 'CBRRESTConnection/Realm'

    ss.dependency 'CloudBridge/Realm'
    ss.dependency 'CloudBridge/CBRRESTConnection'
  end

  s.subspec 'Core' do |ss|
    ss.dependency 'CloudBridge/CoreData+REST'
    ss.dependency 'CloudBridge/Realm+REST'
  end

  s.prefix_header_contents = '#ifndef NS_BLOCK_ASSERTIONS', '#define __assert_unused', '#else', '#define __assert_unused __unused', '#endif'
end
