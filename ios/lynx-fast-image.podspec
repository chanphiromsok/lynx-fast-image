Pod::Spec.new do |s|
  s.name = 'lynx-fast-image'
  s.version = '0.0.1'
  s.summary = 'Native Lynx library'
  s.homepage = 'https://github.com/lynx-family/lynx'
  s.license = { :type => 'Apache-2.0' }
  s.author = 'Lynx'
  s.source = { :path => '..' }
  s.source_files = 'src/**/*.{h,m,mm}'
  s.dependency 'Lynx'
  s.dependency 'LynxServiceAPI'

  s.source_files = 'src/**/*.{h,m,mm}', 'generated/**/*.{cc,h,mm}', 'addon_use.h'
  s.public_header_files = 'addon_use.h'
  s.dependency 'LynxWeakNodeAPI/core'
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}/LynxWeakNodeAPI/packages/weak-node-api/headers"',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) LYNX_LIBRARY_MANUAL_NAPI_REGISTRATION=1 LYNX_LIBRARY_USE_PRIMJS_NAPI_MODULE=1'
  }
end
