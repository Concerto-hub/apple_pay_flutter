#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint apple_pay_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'apple_pay_flutter'
  s.version          = '1.0.3'
  s.summary          = 'Apple Pay Transaction .'
  s.description      = <<-DESC
A new flutter plugin project for Apple Pay Transactions .
                       DESC
  s.homepage         = 'https://github.com/Concerto-hub/apple_pay_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'PaymentGateway' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

end
