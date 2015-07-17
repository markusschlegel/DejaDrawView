#
# Be sure to run `pod lib lint DejaDrawView.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "DejaDrawView"
  s.version          = "0.1.0"
  s.summary          = "A UIView subclass that lets you draw on screen with your finger."
  s.description      = <<-DESC
                       A UIView subclass that lets you draw on screen with your finger. DejaDrawView makes use of Touch Prediction and supports arbitrary touch sampling rates thanks to Touch Coalescing. The project is structured in a way that makes it easy for you to create your own drawing tools (pen, paint brush, pencil …).
                       DESC
  s.homepage         = "https://github.com/markusschlegel/DejaDrawView"
  s.screenshots     = "http://markusschlegel.github.io/JamesBond.PNG"
  s.license          = 'MIT'
  s.author           = { "Markus Schlegel" => "mail@markus-schlegel.com" }
  s.source           = { :git => "https://github.com/markusschlegel/DejaDrawView.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'DejaDrawView/*'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end