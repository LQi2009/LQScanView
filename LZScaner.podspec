
Pod::Spec.new do |s|


  s.name         = "LZScaner"
  s.version      = "0.0.1"
  s.summary      = "LZScaner 二维码的扫描及识别"

  
  s.description  = <<-DESC
                        LZScaner 二维码的扫描及识别, 支持二维码,条形码的识别, 支持长按识别图片中的二维码
                   DESC

  s.homepage     = "https://github.com/LQQZYY/LZScanner_OC"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

   s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author    = "LQQZYY"

  s.platform     = :ios, "8.0"


  s.source       = { :git => "https://github.com/LQQZYY/LZScanner_OC.git", :tag => "#{s.version}" }



  s.source_files  = "LZScaner/*.{h,m}"

   s.resources = "LZScaner/images/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"

  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"

   s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
