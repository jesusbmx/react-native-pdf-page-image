#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(PdfPageImage, NSObject)

RCT_EXTERN_METHOD(generate:(NSString *)filePath withPage:(int)page withScale:(float)scale
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(generateAllPages:(NSString *)filePath withScale:(float)scale
                  withResolver:(RCTPromiseResolveBlock)resolve
                  withRejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
