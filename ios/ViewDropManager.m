

#import "React/RCTViewManager.h"
#import "React/RCTEventEmitter.h"
@interface RCT_EXTERN_MODULE(ViewDropModule, RCTViewManager)
  RCT_EXPORT_VIEW_PROPERTY(onImageReceived, RCTBubblingEventBlock)
@end
