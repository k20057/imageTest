
import Foundation
import UIKit

extension UIImage {
    
    func resize(_ targetSize: CGSize) -> UIImage? {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio / 2, height: size.height * heightRatio / 2)
        } else {
            newSize = CGSize(width: size.width * widthRatio / 2, height: size.height * widthRatio / 2)
        }
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
//        print("resize rect=\(rect)")
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

}
