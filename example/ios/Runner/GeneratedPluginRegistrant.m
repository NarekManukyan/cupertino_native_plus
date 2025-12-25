//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<cupertino_native_plus/CupertinoNativePlugin.h>)
#import <cupertino_native_plus/CupertinoNativePlugin.h>
#else
@import cupertino_native_plus;
#endif

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [CupertinoNativePlugin registerWithRegistrar:[registry registrarForPlugin:@"CupertinoNativePlugin"]];
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
}

@end
