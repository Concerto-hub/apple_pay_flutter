#import "ApplePayFlutterPlugin.h"
#if __has_include(<apple_pay_flutter/apple_pay_flutter-Swift.h>)
#import <apple_pay_flutter/apple_pay_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "apple_pay_flutter-Swift.h"
#endif

@implementation ApplePayFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftApplePayFlutterPlugin registerWithRegistrar:registrar];
}
@end
