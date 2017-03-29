project 'Example/CloudBridge'

source "git@github.com:OliverLetterer/Specs.git"
source "https://github.com/CocoaPods/Specs.git"

# use_frameworks!

abstract_target "iOS" do
    platform :ios, "9.0"

    pod "CloudBridge", :path => "."

    pod 'Expecta', '~> 1.0'
    pod 'OCMock', '< 3.3'

    target "CloudBridge"

    target "Tests" do
        inherit! :search_paths
    end
end
