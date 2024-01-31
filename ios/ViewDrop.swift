


import Foundation

class ViewDrop: UIView, UIDropInteractionDelegate {

  @objc(onImageReceived)
  var onImageReceived : RCTBubblingEventBlock?;
    
    @objc(onDropItemDetected)
    var onDropItemDetected : RCTBubblingEventBlock?;

  init(){
    super.init(frame: CGRect(x: 0, y: 0, width: .max, height: .max))
    self.addInteraction(UIDropInteraction.init(delegate: self)) //added Drop interaction
  }

  required init?(coder: NSCoder) {
    fatalError("ViewDrop init() has not been implemented")
  }

  let pngPrefix = "data:image/png;base64,"
  let jpegPrefix = "data:image/jpeg;base64,"

  func hasAlpha (image : UIImage) -> Bool {
    let alpha = image.cgImage?.alphaInfo
    return (
      alpha == CGImageAlphaInfo.first ||
      alpha == CGImageAlphaInfo.last ||
      alpha == CGImageAlphaInfo.premultipliedFirst ||
      alpha == CGImageAlphaInfo.premultipliedLast
    )
  }


  func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
    session.loadObjects(ofClass: UIImage.self) { imageItems in
      if self.onImageReceived != nil {
        let images = imageItems as! [UIImage]
        guard var oneImg = images.first else {return}
        let widthImage = oneImg.cgImage?.width ?? 800
        let heightImage = oneImg.cgImage?.height ?? 800

        if(widthImage > 6048 || heightImage > 4032) {
          oneImg = oneImg.vImageScaledImageWithSize(destSize: CGSizeMake(2048, 2048),contentMode: .scaleAspectFit)
        }
        var base64ImgWithPrefix = "";

        if(self.hasAlpha(image: oneImg)){
          guard let base64Img = oneImg.pngData()?.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters) else {return}
          base64ImgWithPrefix = self.pngPrefix.appending(base64Img)
        } else {
          guard let base64Img = oneImg.jpegData(compressionQuality: 1.0)?.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters) else {return}
          base64ImgWithPrefix = self.jpegPrefix.appending(base64Img)
        }
        self.onImageReceived!([ "image" : base64ImgWithPrefix ])
      }
    }
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
    return UIDropProposal(operation: .copy)
  }

  func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
      return session.canLoadObjects(ofClass: UIImage.self)
  }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        if let sendEventToReact = self.onDropItemDetected {
            sendEventToReact([:])
        }
    }
}
