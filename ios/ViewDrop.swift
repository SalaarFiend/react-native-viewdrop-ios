


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

  @objc(onFileReceived)
  var onFileReceived : RCTBubblingEventBlock?;

  @objc(onDropItemDetected)
  var onDropItemDetected : RCTBubblingEventBlock?;

  @objc(onFileItemsReceived)
  var onFileItemsReceived: RCTBubblingEventBlock?

  private let videoType : String = kUTTypeMovie as String
  private let audioType : String = kUTTypeAudio as String
  private let imageType : String = kUTTypeImage as String
  private let fileType : String = kUTTypeData as String

  private var acceptedUTTypes: [String] = []
  @objc private var whiteListExtensions: [String]?
  @objc private var blackListExtensions: [String]?
  @objc private var isEnableMultiDropping: Bool = false
  @objc private var allowPartialDrop: Bool = false
  @objc private var imageResizeMaxWidth:  CGFloat = 0
  @objc private var imageResizeMaxHeight: CGFloat = 0
  @objc private var imageCompressQuality: CGFloat = 1.0
  @objc private var imageResizeMode: NSString = "aspectFit"


  struct FileInfo {
    var fileName: String
    var fileUrl: String
    var typeIdentifier: String
  }

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
      "image": self.imageType,
      "file" : self.fileType
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


  func determineFileType(_ fileExtension: String) -> String {
      // Получаем идентификатор типа файла для расширения
      guard let fileUTType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue() as String? else {
          return "file"
      }

      if UTTypeConformsTo(fileUTType as CFString, kUTTypeImage) {
          return "image"
      } else if UTTypeConformsTo(fileUTType as CFString, kUTTypeMovie) {
          return "video"
      } else if UTTypeConformsTo(fileUTType as CFString, kUTTypeAudio) {
          return "audio"
      } else if UTTypeConformsTo(fileUTType as CFString, kUTTypeData) {
          return "file"
      }

      // Возвращаем otherFiles, если тип не был найден
      return "file"
  }

  func isTypeInAllowedTypeList(_ type : String) -> Bool {
    // if no defiend -> accepts all types
    if(acceptedUTTypes.isEmpty){
      return true
    }

    guard let typeFromMap = fileTypeMapping[type] else { return true }
    return acceptedUTTypes.contains(typeFromMap)
  }

  func isFileInBlackList(_ fileExtension: String) -> Bool {
    guard let extensions = self.blackListExtensions, !extensions.isEmpty else {
      return false // if no defined -> accepts all
    }

    let lowercasedExtensions = extensions.map { $0.lowercased() }

    if lowercasedExtensions.contains(fileExtension.lowercased()) {
      return true
    }

    return false
  }

  func isFileInWhiteList(_ fileExtension: String) -> Bool {
    guard let extensions = self.whiteListExtensions, !extensions.isEmpty else {
      return true // if no defined -> accepts all
    }
    return extensions.map { $0.lowercased() }.contains(fileExtension.lowercased())
  }


  private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
    let origW = CGFloat(image.cgImage?.width  ?? 0)
    let origH = CGFloat(image.cgImage?.height ?? 0)
    guard origW > 0, origH > 0 else { return image }

    let hasCustomLimits = imageResizeMaxWidth > 0 || imageResizeMaxHeight > 0

    let maxW: CGFloat
    let maxH: CGFloat

    if hasCustomLimits {
      maxW = imageResizeMaxWidth  > 0 ? imageResizeMaxWidth  : origW
      maxH = imageResizeMaxHeight > 0 ? imageResizeMaxHeight : origH
    } else {
      guard origW > 6048 || origH > 4032 else { return image }
      maxW = 2048
      maxH = 2048
    }

    guard origW > maxW || origH > maxH else { return image }

    let mode: UIView.ContentMode = (imageResizeMode as String) == "aspectFill"
      ? .scaleAspectFill : .scaleAspectFit
    return image.vImageScaledImageWithSize(destSize: CGSizeMake(maxW, maxH), contentMode: mode) ?? image
  }

  func handleDroppedFiles(files: [FileInfo]) {
      guard isEnableMultiDropping else { return }

      // Параллельная обработка файлов в фоновом потоке
      DispatchQueue.global(qos: .userInitiated).async {
          var groupedFiles = [String: [[String : String]]]()

        NSLog("DROP_INTERACTION_VIEWDROP: DispatchQueue FILES")
          // Обрабатываем каждый файл асинхронно
          for file in files {
            NSLog("DROP_INTERACTION_VIEWDROP: file : \(file)")
              if let url = URL(string: file.fileUrl) {
                  let fileExtension = url.pathExtension.lowercased()
                  let fileType = self.determineFileType(fileExtension)

                  if self.allowPartialDrop {
                    if self.isFileInBlackList(fileExtension) { continue }
                    if !self.isFileInWhiteList(fileExtension) { continue }
                    if !self.isTypeInAllowedTypeList(fileType) { continue }
                  }

                  // Если тип файла еще не существует в groupedFiles, создаем его
                  if groupedFiles[fileType] == nil {
                    groupedFiles[fileType] = []
                  }

                  // Добавляем файл в соответствующую категорию по типу

                var resolvedFileUrl = file.fileUrl

                let needsResize  = self.imageResizeMaxWidth > 0 || self.imageResizeMaxHeight > 0
                let needsQuality = self.imageCompressQuality < 1.0 && self.imageCompressQuality > 0

                if fileType == "image" && (needsResize || needsQuality),
                   let img = UIImage(contentsOfFile: url.path) {
                    let quality = self.imageCompressQuality > 0 ? self.imageCompressQuality : 1.0
                    let resized  = needsResize ? self.resizeImageIfNeeded(img) : img
                    let tmpPath  = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent(UUID().uuidString + "_" + file.fileName)
                    let data: Data? = self.hasAlpha(image: resized)
                        ? resized.pngData()
                        : resized.jpegData(compressionQuality: quality)
                    if let data = data, (try? data.write(to: tmpPath)) != nil {
                        resolvedFileUrl = tmpPath.path
                    }
                }

                let test = [
                  "fileName" : file.fileName,
                  "fileUrl" : resolvedFileUrl,
                  "typeIdentifier" : file.typeIdentifier
                ]

                groupedFiles[fileType]?.append(test)
              }
          }

          // Когда обработка файлов завершена, передаем результат обратно в основной поток
          DispatchQueue.main.async {
            NSLog("DROP_INTERACTION_VIEWDROP: SEND FILES")
              // Передаем файлы в onFileItemsReceived, если он задан
            self.onFileItemsReceived?([ "data" : groupedFiles ])
          }
      }
  }


  func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {

    //MARK: - Multi dropping check
    if isEnableMultiDropping {
      var droppedFiles: [FileInfo] = []
      let lock = NSLock()
      let dispatchGroup = DispatchGroup()

      for item in session.items {
        guard let typeIdentifier = item.itemProvider.registeredTypeIdentifiers.first else { continue }

        dispatchGroup.enter()

        item.itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { (url, error) in
          defer { dispatchGroup.leave() }
          guard let fileUrl = url else {
            print("Error loading file: \(error?.localizedDescription ?? "Unknown error")")
            return
          }

          let fileName = fileUrl.lastPathComponent
          let fileType = self.determineFileType(fileUrl.pathExtension.lowercased())
          let fileInfo = FileInfo(fileName: fileName, fileUrl: fileUrl.path, typeIdentifier: fileType)

          lock.lock()
          droppedFiles.append(fileInfo)
          lock.unlock()

          print("File added: \(fileInfo)")
        }
      }

      dispatchGroup.notify(queue: .main) {
        if droppedFiles.count > 0 {
          self.handleDroppedFiles(files: droppedFiles)
        }
      }

      return
    }

    //MARK: - Image send event
    if(session.canLoadObjects(ofClass: UIImage.self)){
      session.loadObjects(ofClass: UIImage.self) { imageItems in
        if self.onImageReceived != nil {
          let images = imageItems as! [UIImage]
          guard var oneImg = images.first else {return}
          oneImg = self.resizeImageIfNeeded(oneImg)
          var base64ImgWithPrefix = "";

          if(self.hasAlpha(image: oneImg)){
            guard let base64Img = oneImg.pngData()?.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters) else {return}
            base64ImgWithPrefix = self.pngPrefix.appending(base64Img)
          } else {
            guard let base64Img = oneImg.jpegData(compressionQuality: self.imageCompressQuality > 0 ? self.imageCompressQuality : 1.0)?.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters) else {return}
            base64ImgWithPrefix = self.jpegPrefix.appending(base64Img)
          }
          self.onImageReceived!([ "image" : base64ImgWithPrefix ])
        }
      }
      return
    }

    guard let item = session.items.first else { return }

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

    // MARK: - Generic file send event
    if self.onFileReceived != nil {
      guard let typeIdentifier = item.itemProvider.registeredTypeIdentifiers.first else { return }
      item.itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
        guard let fileUrl = url else { return }
        let fileName = fileUrl.lastPathComponent
        let tmpDir = NSTemporaryDirectory()
        let destUrl = URL(fileURLWithPath: tmpDir).appendingPathComponent(fileName)
        try? FileManager.default.copyItem(at: fileUrl, to: destUrl)
        DispatchQueue.main.async {
          self.onFileReceived!([
            "fileInfo": [
              "fileName": fileName,
              "fullUrl": destUrl.absoluteString,
              "typeIdentifier": typeIdentifier
            ]
          ])
        }
      }
    }
  }



  private func shouldAcceptDrop(_ session: UIDropSession) -> Bool {
    if isEnableMultiDropping && allowPartialDrop { return true }
    return checkItemsConforimng(session) && checkExtensions(session)
  }

  func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
    return UIDropProposal(operation: shouldAcceptDrop(session) ? .copy : .forbidden)
  }

  func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
    // Always engage when there are items so sessionDidUpdate can show .forbidden indicator
    return !session.items.isEmpty
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
    let whiteListCheck = isAllowedByWhiteList(session)
    let blackListCheck = isAllowedByBlackList(session)

    return whiteListCheck && blackListCheck
  }

  private func isAllowedByWhiteList(_ session: UIDropSession) -> Bool {
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

  private func isAllowedByBlackList(_ session: UIDropSession) -> Bool {
    guard let extensions = self.blackListExtensions, !extensions.isEmpty else {
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

      if lowercasedExtensions.contains(fileExtension.lowercased()) {
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
