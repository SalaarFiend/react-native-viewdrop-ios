

#import "React/RCTViewManager.h"
#import "React/RCTEventEmitter.h"
#import "react_native_viewdrop_ios-Swift.h"
@interface RCT_EXTERN_MODULE(ViewDropModule, RCTViewManager)
  RCT_EXPORT_VIEW_PROPERTY(onImageReceived, RCTBubblingEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onVideoReceived, RCTBubblingEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onAudioReceived, RCTBubblingEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(onDropItemDetected, RCTBubblingEventBlock)
  RCT_EXPORT_VIEW_PROPERTY(fileTypes, NSArray)
@end
