#
# Be sure to run `pod lib lint CBRRESTConnection.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CBRRESTConnection"
  s.version          = "1.1.0"
  s.summary          = "CloudBridgeConnection for RESTful web services."
  s.homepage         = "https://github.com/Cloud-Bridge/CBRRESTConnection"
  s.license          = 'MIT'
  s.author           = { "Oliver Letterer" => "oliver.letterer@gmail.com" }
  s.source           = { :git => "https://github.com/Cloud-Bridge/CloudBridge.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/oletterer'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'CBRRESTConnection'

  s.frameworks = 'CoreData'
  s.dependency 'AFNetworking', '~> 2.5'
  s.dependency 'CloudBridge', '~> 1.0'
end
