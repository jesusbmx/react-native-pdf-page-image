require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-pdf-page-image"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  # RN >= 0.73 / Expo SDK 54 require iOS 12.4+; PDFKit also needs iOS 11+.
  s.platforms    = { :ios => "12.4" }
  s.source       = { :git => "https://github.com/jesusbmx/react-native-pdf-page-image.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"
  # Explicit Swift version to keep Xcode 15+ happy when compiling pod targets.
  s.swift_version = "5.0"
  # So the app that links this static lib finds Swift compatibility libs (swiftCompatibility56, etc.) with Xcode 16+.
  s.user_target_xcconfig = { "LIBRARY_SEARCH_PATHS" => '$(inherited) "$(SDKROOT)/usr/lib/swift"' }

  # Prefer React Native's helper when available (RN >= 0.73 / Expo SDK 54),
  # so dependencies like vendored Folly are provided centrally and not duplicated.
  if defined?(install_modules_dependencies)
    install_modules_dependencies(s)
  else
    s.dependency "React-Core"
  end
end
