


import Foundation
import UniformTypeIdentifiers
import MobileCoreServices
import AVFoundation

import os

class ViewDrop: UIView, UIDropInteractionDelegate {
    
    @objc(onImageReceived)
    var onImageReceived : RCTBubblingEventBlock?;
    
    @objc(onVideoReceived)
    var onVideoReceived : RCTBubblingEventBlock?;
    
    @objc(onDropItemDetected)
    var onDropItemDetected : RCTBubblingEventBlock?;
    
    var videoType : String = ""
    
    init(){
        super.init(frame: CGRect(x: 0, y: 0, width: .max, height: .max))
        self.addInteraction(UIDropInteraction.init(delegate: self)) //added Drop interaction
        if #available(iOS 14.0, *) {
            videoType = UTType.audiovisualContent.description
        } else {
            videoType = kUTTypeAudiovisualContent as String
        }
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
        if #available(iOS 14.0, *) {
            Logger().log("SESSION OBJECTS,\(session.items)")
        } else {
            // Fallback on earlier versions
        }
        
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
            item.itemProvider.loadDataRepresentation(forTypeIdentifier: videoType,completionHandler: {(data,error) in
                
                guard let data = data else {return}
                
                let asset = data.getAVAsset()
                
                
                if #available(iOS 14.0, *) {
                    Logger().log("FULL URL 2: \(asset.fullUrl!)")
                } else {
                    // Fallback on earlier versions
                }
                
                self.onVideoReceived!(["videoInfo" : [
                    "fileName" : asset.fileName,
                    "fullUrl" : asset.fullUrl!.absoluteString,
                ]])
                
            })
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        
        let hasVideo = session.hasItemsConforming(toTypeIdentifiers: [videoType])
        
        return hasVideo || session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        if let sendEventToReact = self.onDropItemDetected {
            sendEventToReact([:])
        }
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


extension Data {
    func getAVAsset() -> VideoAV {
        let directory = NSTemporaryDirectory()
        let fileName = "\(NSUUID().uuidString).mov"
        let fullURL = NSURL.fileURL(withPathComponents: [directory, fileName])
        try! self.write(to: fullURL!)
        let asset = AVAsset(url: fullURL!)
        
        if #available(iOS 14.0, *) {
            Logger().log("FULL URL: \(fullURL!)")
        } else {
            // Fallback on earlier versions
        }
        let result = VideoAV(asset: asset, fullUrl: fullURL!, fileName: fileName)
        return result
    }
}
