import UIKit
import ImageIO

extension UIImage {
    static func resizeImage(data: Data, to targetSize: CGSize) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height)
        ]

        guard let imageSource = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            print("Error: Could not create image source.")
            return nil
        }

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            print("Error: Could not create thumbnail from image source.")
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
