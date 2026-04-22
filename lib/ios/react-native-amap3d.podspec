require "json"

package = JSON.parse(File.read(File.join(__dir__, "../../package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-amap3d"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/qiuxiang/react-native-amap3d.git", :tag => "#{s.version}" }

  s.source_files = "**/*.{h,m,mm,swift}"

  s.dependency "React-Core"
  s.dependency 'AMap3DMap', "~> 9.7.0"

  # AMap3DMap 9.x 的二进制中含有未对齐指针（protobuf 生成代码），
  # Xcode 15+ 新链接器（ld_prime）严格校验会报错，需回退到经典链接器。
  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '-ld_classic' }
end
