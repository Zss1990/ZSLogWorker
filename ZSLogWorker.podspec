
Pod::Spec.new do |s|
  s.name     = 'ZSLogWorker'
  s.version  = '0.0.1'
  s.license  = 'MIT'
  s.summary  = 'A delightful iOS log framework.'
  s.homepage = 'https://github.com/Zss1990/ZSLogWorker.git'
  s.social_media_url = 'https://github.com/Zss1990/ZSLogWorker.git'
  s.authors  = { 'zhushuaishuai' => 'zhushuaishuai163@163.com' }
  s.source   = { :git => 'https://github.com/Zss1990/ZSLogWorker.git', :tag => s.version, :submodules => true }
  s.requires_arc = true
  s.description  = <<-DESC
                    日志管理库
                   DESC

  s.platform     = :ios
  s.ios.deployment_target = "8.0"

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "ZSLogWorker/**/*.{h,m}"
  s.public_header_files = "ZSLogWorker/**/*.h"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.ios.frameworks  = 'UIKit','Foundation'

  s.dependency 'SSZipArchive'
  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.pod_target_xcconfig  = {
    'FRAMEWORK_SEARCH_PATHS'        => '$(inherited) ${PODS_ROOT}/**',
    'LIBRARY_SEARCH_PATHS'          => '$(inherited) ${PODS_ROOT}/**',
    'ENABLE_BITCODE'                => 'NO',
    'OTHER_LDFLAGS'                 => '$(inherited) -ObjC',
    'STRINGS_FILE_OUTPUT_ENCODING'  => 'UTF-8',
    # 'ONLY_ACTIVE_ARCH'              => 'YES'
  }

end
