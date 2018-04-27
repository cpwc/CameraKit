Pod::Spec.new do |s|

  s.name         = "CameraKit"
  s.version      = "0.1.0"
  s.summary      = "Sony  camera API library written by swift"

  s.description  = <<-DESC
                   swift API library for Sony  camera this library provides API wrapper to connect to Sony  Camera easily.

                   DESC

  s.homepage     = "https://github.com/cpwc/CameraKit"
  s.license      = "MIT"
  s.author       = { "cpwc" => "calvinpohwc@gmail.com" }
  s.homepage     = "https://www.cpwc.me"

  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/cpwc/CameraKit.git", :tag => "0.1.0" }

  s.source_files  = "CameraKit", "CameraKit/**/*.{h,m,swift}"
  s.requires_arc = true
  
end
