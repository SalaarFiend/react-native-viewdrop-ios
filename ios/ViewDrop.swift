


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
  
  
  
  
  func determineFileType(from url: URL) -> String {
      let fileExtension = url.pathExtension.lowercased()

      // Получаем идентификатор типа файла для расширения
      guard let fileUTType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue() as String? else {
          return "otherFiles"
      }

    NSLog("DROP_INTERACTION_VIEWDROP: determineFileType : \(fileUTType) : imageType is : \(imageType)")
      if UTTypeConformsTo(fileUTType as CFString, kUTTypeImage) {
          return "image"
      } else if UTTypeConformsTo(fileUTType as CFString, kUTTypeMovie) {
          return "video"
      } else if UTTypeConformsTo(fileUTType as CFString, kUTTypeAudio) {
          return "audio"
      } else if UTTypeConformsTo(fileUTType as CFString, kUTTypeData) {
          return "otherFiles"
      }

      // Возвращаем otherFiles, если тип не был найден
      return "otherFiles"
  }
  

  func handleDroppedFiles(files: [FileInfo]) {
    NSLog("DROP_INTERACTION_VIEWDROP: CHECK isEnableMultiDropping: \(isEnableMultiDropping)")
      guard isEnableMultiDropping else { return }

      // Параллельная обработка файлов в фоновом потоке
      DispatchQueue.global(qos: .userInitiated).async {
          var groupedFiles = [String: [[String : String]]]()

        NSLog("DROP_INTERACTION_VIEWDROP: DispatchQueue FILES")
          // Обрабатываем каждый файл асинхронно
          for file in files {
            NSLog("DROP_INTERACTION_VIEWDROP: file : \(file)")
              if let url = URL(string: file.fileUrl) {
                
                  let fileType = self.determineFileType(from: url)
                  // Если тип файла еще не существует в groupedFiles, создаем его
                  if groupedFiles[fileType] == nil {
                    groupedFiles[fileType] = []
                  }
                
                  // Добавляем файл в соответствующую категорию по типу
                
                let test = [
                  "fileName" : file.fileName,
                  "fileUrl" : file.fileUrl,
                  "typeIdentifier" : file.typeIdentifier
                ]
                
                groupedFiles[fileType]?.append(test)
              }
          }

          // Когда обработка файлов завершена, передаем результат обратно в основной поток
          DispatchQueue.main.async {
            NSLog("DROP_INTERACTION_VIEWDROP: SEND FILES")
              // Передаем файлы в onFileItemsReceived, если он задан
            self.onFileItemsReceived!([ "data" : groupedFiles ])
          }
      }
  }
  
  
  func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
    
    //MARK: - Multi dropping check
    if session.items.count > 1 && isEnableMultiDropping {
      var droppedFiles: [FileInfo] = []
      
      let dispatchGroup = DispatchGroup()  // Группа для синхронизации асинхронных задач
      
      // Получаем файлы из session.items
      for item in session.items {
        // Проверяем, какой тип данных зарегистрирован для item
        guard let typeIdentifier = item.itemProvider.registeredTypeIdentifiers.first else { continue }
        
        dispatchGroup.enter()  // Входим в группу
        
        // Используем loadFileRepresentation для загрузки файла
        item.itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { (url, error) in
          // Если URL не получен, выводим ошибку
          guard let fileUrl = url else {
            print("Error loading file: \(error?.localizedDescription ?? "Unknown error")")
            dispatchGroup.leave()  // Выходим из группы в случае ошибки
            return
          }
          
          // Получаем имя файла и расширение
          let fileName = fileUrl.lastPathComponent
          
          // Определяем тип файла по расширению
          let typeIdentifier = self.determineFileType(from: fileUrl)
          
          // Создаем объект FileInfo
          let fileInfo = FileInfo(fileName: fileName, fileUrl: fileUrl.path, typeIdentifier: typeIdentifier)
          
          // Добавляем файл в массив
          droppedFiles.append(fileInfo)
          
          // Логируем для отладки
          print("File added: \(fileInfo)")
          
          dispatchGroup.leave()  // Выходим из группы после завершения обработки этого файла
        }
      }
      
      // Ожидаем завершения всех асинхронных операций перед передачей данных
      dispatchGroup.notify(queue: .main) {
        // Когда все файлы обработаны, вызываем handleDroppedFiles
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
  
  
  
  func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
    if(checkItemsConforimng(session) && checkExtensions(session)){
      return UIDropProposal(operation: .copy)
    }
    return UIDropProposal(operation: .forbidden)
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
    let whiteListCheck = checkWhiteList(session)
    let blackListCheck = checkBlackList(session)
    
    return whiteListCheck && blackListCheck
  }
  
  private func checkWhiteList(_ session: UIDropSession) -> Bool {
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
  
  private func checkBlackList(_ session: UIDropSession) -> Bool {
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
