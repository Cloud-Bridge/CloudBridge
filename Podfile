project 'Example/CloudBridge'

source "https://github.com/CocoaPods/Specs.git"

use_frameworks!

abstract_target "iOS" do
    platform :ios, "9.0"

    pod "CloudBridge/Core", :path => "."

    pod 'Expecta', '~> 1.0'
    pod 'OCMock', '< 3.3'

    target "CloudBridge"
    target "Tests"
end
