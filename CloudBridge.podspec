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
  s.version          = "1.4.3"
  s.summary          = "The missing bridge between Your CoreData model and various Cloud backends."
  s.homepage         = "https://github.com/OliverLetterer"
  s.license          = 'MIT'
  s.author           = { "Oliver Letterer" => "oliver.letterer@gmail.com" }
  s.source           = { :git => "https://github.com/OliverLetterer/CloudBridge.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/oletterer'

  s.platforms    = { :ios => '8.0', :tvos => '9.0', :watchos => '2.0' }
  s.requires_arc = true

  s.source_files = 'CloudBridge'

  s.frameworks = 'CoreData'
  s.dependency 'SLCoreDataStack', '~> 1.0'
  s.dependency 'CBRManagedObjectCache', '~> 1.4'

  s.prefix_header_contents = '#ifndef NS_BLOCK_ASSERTIONS', '#define __assert_unused', '#else', '#define __assert_unused __unused', '#endif'
end
