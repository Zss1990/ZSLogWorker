
Pod::Spec.new do |s|

  s.name         = "ZSLogWorker"
  s.version      = "0.0.1"
  s.summary      = "A short description of ZSLogWorker."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
                    日志管理库
                   DESC

  s.homepage         = 'https://github.com/'
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license = {:type => "zhushuaishuai", :file =>"LICENSE"}
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author             = { "zhushuaishuai" => "zhushuaishuai@hikvision.com.cn@hikvision.com.cn" }
  # Or just: s.author    = "zhushuaishuai"
  # s.authors            = { "zhushuaishuai" => "zhushuaishuai@hikvision.com.cn@hikvision.com.cn" }
  # s.social_media_url   = "http://twitter.com/zhushuaishuai"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.platform     = :ios
  s.ios.deployment_target = "8.0"


  # s.source       = { :git => "http://github.com/ZSLogWorker.git", :tag => "#{s.version}" }
  s.source           = { :git => 'https://github.com/yangzmpang/ALSLog.git', :tag => s.version.to_s }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "ZSLogWorker", "ZSLogWorker/**/*.{h,m}"
  s.exclude_files = "ZSLogWorker/Exclude"

  s.public_header_files = "Classes/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.ios.frameworks  = 'UIKit','Foundation'

  s.dependency 'SSZipArchive'
  # s.dependency 'AFNetworking'
  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  s.requires_arc = true

  s.pod_target_xcconfig  = {
    'FRAMEWORK_SEARCH_PATHS'        => '$(inherited) ${PODS_ROOT}/**',
    'LIBRARY_SEARCH_PATHS'          => '$(inherited) ${PODS_ROOT}/**',
    'ENABLE_BITCODE'                => 'NO',
    'OTHER_LDFLAGS'                 => '$(inherited) -ObjC',
    'STRINGS_FILE_OUTPUT_ENCODING'  => 'UTF-8',
    'ONLY_ACTIVE_ARCH'              => 'NO'
  }

end
