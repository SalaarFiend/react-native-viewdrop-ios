


import Foundation
import UniformTypeIdentifiers
import MobileCoreServices
import AVFoundation

import os

@objc(ViewDrop)
class ViewDrop: UIView, UIDropInteractionDelegate {

  @objc(onImageReceived)
  var onImageReceived : RCTBubblingEventBlock?;

  @objc(onVideoReceived)
  var onVideoReceived : RCTBubblingEventBlock?;

  @objc(onAudioReceived)
  var onAudioReceived : RCTBubblingEventBlock?;

  @objc(onDropItemDetected)
  var onDropItemDetected : RCTBubblingEventBlock?;

  private let videoType : String = kUTTypeMovie as String
  private let audioType : String = kUTTypeAudio as String
  private let imageType : String = kUTTypeImage as String

  private var acceptedUTTypes: [String] = []
  
  @objc private var whiteListExtensions: [String]?

  @objc var fileTypes: NSArray = [] {
    didSet {
      acceptedUTTypes = fileTypes.compactMap { ($0 as? String).flatMap { fileTypeMapping[$0] } }
    }
  }

  private var fileTypeMapping: [String: String] = [:]

  init(){
    super.init(frame: CGRect(x: 0, y: 0, width: .max, height: .max))
    self.addInteraction(UIDropInteraction.init(delegate: self)) //added Drop interaction
    self.fileTypeMapping = [
      "video": self.videoType,
      "audio": self.audioType,
      "image": self.imageType
    ]
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
    //MARK: - Image send event
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

    for item in session.items {
      //MARK: - Video send event
      if(item.itemProvider.hasItemConformingToTypeIdentifier(videoType)){
        item.itemProvider.loadDataRepresentation(forTypeIdentifier: videoType,completionHandler: {(data,error) in
          guard let data = data else {return}

          if #available(iOS 16.0, *) {
            guard let fileExtension = item.itemProvider.registeredContentTypes[0].preferredFilenameExtension else {return}

            let asset = data.getAVoAsset(extenstion: fileExtension)

            self.onVideoReceived!(["videoInfo" : [
              "fileName" : asset.fileName,
              "fullUrl" : asset.fullUrl!.absoluteString,
            ]])
            return
          } else {
            item.itemProvider.loadFileRepresentation(forTypeIdentifier: self.videoType, completionHandler: { url, _ in
              guard let fileExtension = url?.pathExtension else {return}
              let asset = data.getAVoAsset(extenstion: fileExtension)

              self.onVideoReceived!(["videoInfo" : [
                "fileName" : asset.fileName,
                "fullUrl" : asset.fullUrl!.absoluteString,
              ]])
            }
            )
          }
        })
        return
      }
      // MARK: - Audio send event
      if(item.itemProvider.hasItemConformingToTypeIdentifier(audioType)){
        item.itemProvider.loadDataRepresentation(forTypeIdentifier: audioType,completionHandler: {(data,error) in
          guard let data = data else {return}

          if #available(iOS 16.0, *) {
            guard let fileExtension = item.itemProvider.registeredContentTypes[0].preferredFilenameExtension else {return}

            let asset = data.getAVoAsset(extenstion: fileExtension)

            self.onAudioReceived!(["audioInfo" : [
              "fileName" : asset.fileName,
              "fullUrl" : asset.fullUrl!.absoluteString,
            ]])
            return
          } else {
            item.itemProvider.loadFileRepresentation(forTypeIdentifier: self.videoType, completionHandler: { url, _ in
              guard let fileExtension = url?.pathExtension else {return}
              let asset = data.getAVoAsset(extenstion: fileExtension)

              self.onAudioReceived!(["audioInfo" : [
                "fileName" : asset.fileName,
                "fullUrl" : asset.fullUrl!.absoluteString,
              ]])
            }
            )
          }
        })
        return
      }
    }
  }

  func canLoadTypeOfObjects (_ session: UIDropSession) -> Bool {
    let hasTypes = session.hasItemsConforming(toTypeIdentifiers: [videoType,audioType])

    return hasTypes || session.canLoadObjects(ofClass: UIImage.self)
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
    if(canLoadTypeOfObjects(session)){
      return UIDropProposal(operation: .copy)
    }
    return UIDropProposal.init(operation: .forbidden)
  }

  func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
    return checkItemsConforimng(session) && checkExtensions(session)
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
    if let sendEventToReact = self.onDropItemDetected {
      sendEventToReact([:])
    }
  }
  
  private func checkItemsConforimng(_ session: UIDropSession) -> Bool {
    // if no defiend -> accepts all types
    if(acceptedUTTypes.isEmpty){
      return true
    }
    return session.hasItemsConforming(toTypeIdentifiers: acceptedUTTypes)
  }

  private func checkExtensions(_ session: UIDropSession) -> Bool {
      guard let extensions = self.whiteListExtensions, !extensions.isEmpty else {
          return true // if no defined -> accepts all
      }
      
      let lowercasedExtensions = extensions.map { $0.lowercased() }
      
      for item in session.items {
          guard let typeIdentifier = item.itemProvider.registeredTypeIdentifiers.first,
                let unmanagedFileExtension = UTTypeCopyPreferredTagWithClass(
                  typeIdentifier as CFString,
                  kUTTagClassFilenameExtension
                ),
                let fileExtension = unmanagedFileExtension.takeRetainedValue() as String? else {
              return false
          }
          if !lowercasedExtensions.contains(fileExtension.lowercased()) {
              return false
          }
      }
      
      return true
  }
}

struct VideoAV {
  var asset : AVAsset? = nil
  var fullUrl : URL? = nil
  var fileName = ""
  init(asset : AVAsset, fullUrl : URL, fileName : String){
    self.asset = asset
    self.fullUrl = fullUrl
    self.fileName = fileName
  }
}

struct AVAssetForRN {
  var asset : AVAsset? = nil
  var fullUrl : URL? = nil
  var fileName = ""
  init(asset : AVAsset, fullUrl : URL, fileName : String){
    self.asset = asset
    self.fullUrl = fullUrl
    self.fileName = fileName
  }
}


extension Data {
  func getAVoAsset(extenstion : String) -> AVAssetForRN {
    let directory = NSTemporaryDirectory()
    let fileName = "\(NSUUID().uuidString).\(extenstion)"
    let fullURL = NSURL.fileURL(withPathComponents: [directory, fileName])
    try! self.write(to: fullURL!)
    let asset = AVAsset(url: fullURL!)
    let result = AVAssetForRN(asset: asset, fullUrl: fullURL!, fileName: fileName)
    return result
  }

}
