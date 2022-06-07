#
# Be sure to run `pod lib lint WechatOpenSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AlipaySDK-iOS'
  s.version          = '15.8.10'
  s.summary          = '支付宝SDK v15.8.10'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  支付宝SDK v15.8.10
                       DESC

  s.homepage         = 'https://open.alipay.com/platform/home.htm'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'TheLittleBoy' => 'wangxa@edu-edu.com.cn' }
  s.source           = { :http => 'https://gw.alipayobjects.com/os/bmw-prod/209de7ab-ac38-431f-9d6f-f1d097665953.zip', :type => 'zip' }
  
  s.ios.deployment_target = '9.0'

  s.vendored_frameworks  = 'iOS/AlipaySDK.framework'
  s.resources = 'iOS/AlipaySDK.bundle'

  s.frameworks          = 'Security', 'CoreTelephony', 'UIKit', 'CoreGraphics', 'WebKit', 'CFNetwork', 'QuartzCore', 'CoreMotion', 'CoreText'
  s.libraries           = 'z','c++'

  s.pod_target_xcconfig = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64" , "VALID_ARCHS" => "x86_64 armv7 arm64"}
  s.user_target_xcconfig = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64" }
end
