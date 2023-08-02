import UIKit
import Accelerate

extension UIImage {

    func vImageScaledImageWithSize(destSize:CGSize) -> UIImage! {
      UIGraphicsBeginImageContext(CGSizeMake(destSize.width, destSize.height))
      self.draw(in: CGRectMake(0, 0, destSize.width, destSize.height))
      let newImage:UIImage! = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      return newImage
    }

  func vImageScaledImageWithSize(destSize:CGSize, contentMode:UIView.ContentMode) -> UIImage! {
    let sourceRef:CGImage = self.cgImage!
    let sourceWidth:UInt = UInt(sourceRef.width)
    let sourceHeight:UInt = UInt(sourceRef.height)
    let horizontalRatio:CGFloat = destSize.width / CGFloat(sourceWidth)
    let verticalRatio:CGFloat = destSize.height / CGFloat(sourceHeight)
    var ratio:CGFloat = 0.0

      switch (contentMode) {
      case .scaleAspectFill:
        ratio = max(horizontalRatio, verticalRatio)
        break

      case .scaleAspectFit:
        ratio = min(horizontalRatio, verticalRatio)
        break

      default:
        NSException.raise(NSExceptionName.invalidArgumentException, format:"Unsupported content mode: %d", arguments: getVaList([contentMode.rawValue]) )
      }

    let newSize:CGSize = CGSizeMake(CGFloat(sourceWidth) * ratio, CGFloat(sourceHeight) * ratio)

    return self.vImageScaledImageWithSize(destSize: newSize)
    }
}
