#import "SwitcherPlugin.h"
#if __has_include(<switcher/switcher-Swift.h>)
#import <switcher/switcher-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "switcher-Swift.h"
#endif

@implementation SwitcherPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSwitcherPlugin registerWithRegistrar:registrar];
}
@end
