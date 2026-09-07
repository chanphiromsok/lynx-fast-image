Pod::Spec.new do |s|
  s.name = 'lynx-fast-image'
  s.version = '0.0.1'
  s.summary = 'Native Lynx library'
  s.homepage = 'https://github.com/lynx-family/lynx'
  s.license = { :type => 'Apache-2.0' }
  s.author = 'Lynx'
  s.platforms = { :ios => '13.0' }
  s.swift_version = '5.9'
  s.source = { :path => '..' }
  s.source_files = 'src/**/*.{h,m,mm,swift}'

  # Pin to the same Lynx version the consuming Expo host resolves (4.0.0).
  # A custom element only needs the core framework; it must not pull
  # LynxServiceAPI / LynxService/Image.
  s.dependency 'Lynx', '4.0.0'

  # Share SDWebImage's process-wide cache/loader with Expo Image 57.0.4.
  # Do NOT vendor SDWebImage or pin an exact incompatible version.
  # WebP still images use the built-in `SDImageAWebPCoder` (iOS 14+); the
  # libwebp-based `SDWebImageWebPCoder` pod is added in the animated-WebP phase.
  s.dependency 'SDWebImage', '~> 5.21.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES'
  }
end
