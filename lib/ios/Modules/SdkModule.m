#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(AMapSdk, NSObject)

RCT_EXTERN_REMAP_METHOD(init, initSdk: (NSString)apiKey)
RCT_EXTERN_METHOD(getVersion: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)_)

@end
