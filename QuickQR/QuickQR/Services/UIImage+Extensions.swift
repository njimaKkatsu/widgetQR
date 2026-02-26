import UIKit
import UIKit
import Vision
import CoreImage

// MARK: - QRcropper (Global Function)
func cropQRCode(from image: UIImage) -> UIImage? {
    // 画像の向き補正
    guard let normalizedImage = image.fixedUpright(),
          let ciImage = CIImage(image: normalizedImage) else { return nil }
    
    // VisionでQRコードを検出
    let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    let request = VNDetectBarcodesRequest()
    request.symbologies = [.qr]
    
    try? handler.perform([request])
    
    guard let observation = request.results?.first as? VNBarcodeObservation else { return nil }
    
    // 座標の取得と変換
    let size = ciImage.extent.size
    
    func scalePoint(_ point: CGPoint, to size: CGSize) -> CGPoint {
        return CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
    
    let corners = [
        scalePoint(observation.topLeft, to: size),
        scalePoint(observation.topRight, to: size),
        scalePoint(observation.bottomLeft, to: size),
        scalePoint(observation.bottomRight, to: size)
    ]
    
    // 重心を計算
    let centerX = corners.map({ $0.x }).reduce(0, +) / 4
    let centerY = corners.map({ $0.y }).reduce(0, +) / 4
    let center = CGPoint(x: centerX, y: centerY)
    
    func expand(_ point: CGPoint) -> CGPoint {
        let factor: CGFloat = 1.05
        let newX = center.x + (point.x - center.x) * factor
        let newY = center.y + (point.y - center.y) * factor
        return CGPoint(
            x: max(0, min(size.width, newX)),
            y: max(0, min(size.height, newY))
        )
    }

    // 歪み補正フィルタ
    guard let filter = CIFilter(name: "CIPerspectiveCorrection") else { return nil }
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(CIVector(cgPoint: expand(corners[0])), forKey: "inputTopLeft")
    filter.setValue(CIVector(cgPoint: expand(corners[1])), forKey: "inputTopRight")
    filter.setValue(CIVector(cgPoint: expand(corners[2])), forKey: "inputBottomLeft")
    filter.setValue(CIVector(cgPoint: expand(corners[3])), forKey: "inputBottomRight")
    
    guard var outputImage = filter.outputImage else { return nil }

    // ホワイトポイント調整
    if let whitePointFilter = CIFilter(name: "CIWhitePointAdjust") {
        whitePointFilter.setValue(outputImage, forKey: kCIInputImageKey)
        whitePointFilter.setValue(CIColor(red: 0.9, green: 0.9, blue: 0.9), forKey: kCIInputColorKey)
        if let result = whitePointFilter.outputImage {
            outputImage = result
        }
    }

    // 彩度とコントラストの調整
    outputImage = outputImage.applyingFilter("CIColorControls", parameters: [
        kCIInputSaturationKey: 1.0,
        kCIInputContrastKey: 1.05,
        kCIInputBrightnessKey: 0.0
    ])
    
    // 露出を微調整
    outputImage = outputImage.applyingFilter("CIExposureAdjust", parameters: [
        kCIInputEVKey: 0.2
    ])

    // 出力
    let context = CIContext()
    guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
    let rawImage = UIImage(cgImage: cgImage)
    
    return rawImage.withRoundedCorners(radius: 16)
}

// MARK: - UIImage Extensions
extension UIImage {
    func fixedUpright() -> UIImage? {
        if self.imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
    func withRoundedCorners(radius: CGFloat) -> UIImage? {
        let rect = CGRect(origin: .zero, size: self.size)
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        path.addClip()
        self.draw(in: rect)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return roundedImage
    }
}
