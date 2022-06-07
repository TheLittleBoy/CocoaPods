Pod::Spec.new do |s|
  s.name = "HXWechatOpenSDK"
  s.version = "1.9.2"
  s.summary = "HXWechatOpenSDK is a remade module framework for WeChat SDK."

  s.homepage = "https://github.com/nuomi1/NBus"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "nuomi1" => "nuomi1@qq.com" }
  s.source = { :http => "https://ghcr.io/v2/nuomi1/nbus/nbuswechatsdk/blobs/sha256:3ea28f9e2e52cc3774d13e10376d55c7a2132998b26290ec7c482d77ac5f4635",
               :flatten => false, :type => "tgz", :sha256 => "3ea28f9e2e52cc3774d13e10376d55c7a2132998b26290ec7c482d77ac5f4635",
               :headers => ["Authorization: Bearer QQ=="] }

  s.static_framework = true

  s.ios.deployment_target = "9.0"

  s.frameworks = ["CoreGraphics", "UIKit", "WebKit"]
  s.libraries = ["c++"]

  s.vendored_frameworks = ["NBusWechatSDK.framework"]

  s.pod_target_xcconfig = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64" }
  s.user_target_xcconfig = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64" }
end
