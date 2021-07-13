
#
#  Be sure to run `pod spec lint SenderFramework_iOS.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "SenderFramework_iOS"
  s.module_name  = "SenderFramework"
  s.version      = "2.3.0"
  s.summary      = "A short description of SenderFramework_iOS."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
A loooooooooooooooooooong description of SenderFramework_iOS.
                   DESC

  s.homepage     = "https://sender.mobi"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author    = "Middleware Inc."

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  s.platform     = :ios, "9.0"

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/sender-mobi/SenderFramework_iOS", :tag => "#{s.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = ""  
  s.resources = ""
  s.module_map = "SenderFramework/SenderFramework.modulemap"

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.library   = "iconv"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

    s.requires_arc = true

    s.xcconfig = { "OTHER_LDFLAGS" => "-ObjC" }

    s.dependency "libPhoneNumber-iOS", "0.9.10"
    s.dependency "KAProgressLabel", "2.1"
    s.dependency "SAMKeychain", "1.5.2"
    s.dependency "SDWebImage", "4.1.0"
    s.dependency "ObjectiveLuhn", "1.0.2"
    s.dependency "prebuilt-mp3-lame-iOS", "3.99.5"
    s.dependency "MWCoreBitcoin"

    s.default_subspec = "IncludedUI"

    s.subspec "NoUI" do |noUI|
      noUI.source_files  = "SenderFramework/**/*.{h,m,mm,swift,c,cpp,a}"  
      noUI.resources = ["SenderFramework/**/*.{xcdatamodeld,strings,wav,caf}", "SenderFramework/Plists/**/*.plist", "GoogleSignIn.bundle"]
      noUI.prefix_header_file = "SenderFramework/SenderFramework-PrefixHeader.pch"
      noUI.vendored_frameworks = ["GoogleSignIn.framework", "GoogleSignInDependencies.framework"]
      noUI.frameworks = ["SafariServices", "SystemConfiguration", "Security", "CoreLocation", "QuartzCore", "AudioToolbox", "AVFoundation", "CoreGraphics", "Foundation", "UIKit", "AddressBook", "AddressBookUI", "CoreData", "SystemConfiguration", "MessageUI", "MobileCoreServices"]
    end

    s.subspec "IncludedUI" do |includedUI|
      includedUI.dependency 'SenderFramework_iOS/NoUI'
      includedUI.resource_bundles = {
        'SenderFrameworkResources' => ["SenderFramework/**/*.{txt,rtf,xib,storyboard,xcassets}", "SenderFrameworkResources/Plists/**/*.plist", "SenderFrameworkResources/**/*.{txt,rtf,xib,storyboard,xcassets}"]
      }
    end

    s.subspec "GoogleMaps" do |googleMaps|
      googleMaps.dependency 'SenderFramework_iOS/IncludedUI'
      googleMaps.xcconfig = { 
        "OTHER_CFLAGS" => "-DSENDER_FRAMEWORK_USE_GOOGLE_MAPS -fno-modules",
        "OTHER_SWIFT_FLAGS" => "-DSENDER_FRAMEWORK_USE_GOOGLE_MAPS"
      }
      googleMaps.vendored_frameworks = ["GoogleMapsBase.framework", "GoogleMaps.framework", "GoogleMapsCore.framework"]
      googleMaps.resources = ["GoogleMaps.framework/Resources/GoogleMaps.bundle"]
      googleMaps.frameworks = ["Accelerate", "CoreData", "CoreGraphics", "CoreLocation", "CoreText", "GLKit", "ImageIO", "OpenGLES", "QuartzCore", "SystemConfiguration", "UIKit"]
      googleMaps.libraries = ["c++", "z"]
    end

    s.subspec "GoogleMapsM4B" do |googleMapsM4B|
      googleMapsM4B.dependency 'SenderFramework_iOS/GoogleMaps'
      googleMapsM4B.vendored_frameworks = ["GoogleMapsM4B.framework"]
    end
end
