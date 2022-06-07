#
# Be sure to run `pod lib lint WechatOpenSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WechatOpenSDK'
  s.version          = '1.9.2'
  s.summary          = '微信支付SDK v1.9.2'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  微信支付SDK v1.9.2 完整版
                       DESC

  s.homepage         = 'https://mp.weixin.qq.com'
  s.license          = { :type => 'MIT', :text => 'LICENSE' }
  s.author           = { 'TheLittleBoy' => 'wangxa@edu-edu.com.cn' }
  s.source           = { :http => 'https://res.wx.qq.com/op_res/XP2S6Df6fFmoNCdbbD14fbkHfjxvl3Q4lw61HkI79tjBQjppRTgJSmJ1cYKIXZdQh9IeX2xXCWX7AqnzuWfUvw', :type => 'zip' }
  
  s.ios.deployment_target = '9.0'

  # s.public_header_files = "OpenSDK1.9.2/*.h"
  s.source_files = 'OpenSDK1.9.2/*.{h}'
  
  s.vendored_libraries  = 'OpenSDK1.9.2/*.a'
  s.frameworks          = 'Security', 'CoreTelephony', 'UIKit', 'CoreGraphics', 'WebKit'
  s.libraries           = 'z', 'sqlite3.0', 'c++'

  s.requires_arc = false
  
end
