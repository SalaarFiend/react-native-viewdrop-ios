


import Foundation

@objc(ViewDropModule)
class ViewDropModule : RCTViewManager {

  @objc
  override static func requiresMainQueueSetup() -> Bool {
      return true
    }

  @objc
  override func view ()-> UIView! {
    let viewDrop = ViewDrop()
    return viewDrop
  }
}
