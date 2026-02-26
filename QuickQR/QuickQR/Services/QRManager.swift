import SwiftUI
import WidgetKit
import Foundation
import Combine


// MARK: - マネージャー

final class QRManager: ObservableObject {
    @Published var qrItems: [QRGridItemModel] = []
    
    // AppGroup用のUserDefaultsを定義
    private let sharedDefaults = UserDefaults(suiteName: "group.com.katzo.quickqr")
    
    @Published var isWidgetPrivateMode: Bool = false {
        didSet {
            guard oldValue != isWidgetPrivateMode else { return }
            sharedDefaults?.set(isWidgetPrivateMode, forKey: "isWidgetPrivateMode")
            WidgetCenter.shared.reloadAllTimelines()
            
            if let favorite = qrItems.first(where: { $0.isFavorite }) {
                updateWidgetImage(image: favorite.image, name: favorite.name, category: favorite.category)
            } else {
                clearWidgetImage()
            }
        }
    }

    init() {
        self.qrItems = loadQRItems()
        self.isWidgetPrivateMode = sharedDefaults?.bool(forKey: "isWidgetPrivateMode") ?? false
    }
    
    // --- 追加: 画像からQRコードの文字列を抽出 ---
    func scanQRCode(from image: UIImage) -> String {
        guard let ciImage = CIImage(image: image) else { return "" }
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) as? [CIQRCodeFeature]
        return features?.first?.messageString ?? ""
    }

    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func saveQRImageToAppGroup(_ image: UIImage) {
        let targetSize = CGSize(width: 400, height: 400)
        let resizedImage = resizeImage(image: image, targetSize: targetSize)
        let url = AppGroup.latestQRImageURL
        guard let data = resizedImage.pngData() else { return }
        
        do {
            try data.write(to: url, options: [.atomic])
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ Widget image saved successfully")
        } catch {
            print("❌ Widget image save failed: \(error)")
        }
    }

    // 名前のついた保存処理（既存）
    func saveQRImageToAppGroup(image: UIImage, name: String, category: QRCategory) {
        updateWidgetImage(image: image, name: name, category: category)
    }

    // メインアプリ内保存
    func saveQRItems(_ items: [QRGridItemModel]) {
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let jsonURL = docURL.appendingPathComponent("qr_items.json")

        let encodableItems = items.map { item in
            EncodableQRItem(
                id: item.id.uuidString,
                name: item.name,
                category: item.category.rawValue,
                fileName: "\(item.id).png",
                isFavorite: item.isFavorite,
                qrContent: item.qrContent
            )
        }

        if let data = try? JSONEncoder().encode(encodableItems) {
            try? data.write(to: jsonURL)
        }

        for item in items {
            if let data = item.image.pngData() {
                let imageURL = docURL.appendingPathComponent("\(item.id).png")
                try? data.write(to: imageURL)
            }
        }

        if let favoriteItem = items.first(where: { $0.isFavorite }) {
            updateWidgetImage(image: favoriteItem.image, name: favoriteItem.name, category: favoriteItem.category)
        } else {
            clearWidgetImage()
        }
    }
    
    // 読み込み
    func loadQRItems() -> [QRGridItemModel] {
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let jsonURL = docURL.appendingPathComponent("qr_items.json")
        
        guard let data = try? Data(contentsOf: jsonURL),
              let savedItems = try? JSONDecoder().decode([EncodableQRItem].self, from: data) else {
            return []
        }

        return savedItems.compactMap { saved in
            let imageURL = docURL.appendingPathComponent(saved.fileName)
            
            if let data = try? Data(contentsOf: imageURL),
               let image = UIImage(data: data),
               let category = QRCategory(rawValue: saved.category) {
                
                return QRGridItemModel(
                    id: UUID(uuidString: saved.id) ?? UUID(),
                    image: image,
                    category: category,
                    name: saved.name,
                    isFavorite: saved.isFavorite,
                    qrContent: saved.qrContent
                )
            }
            return nil
        }
    }
    
    func toggleFavorite(id: UUID) {
        for index in qrItems.indices {
            if qrItems[index].id != id {
                qrItems[index].isFavorite = false
            }
        }

        if let index = qrItems.firstIndex(where: { $0.id == id }) {
            qrItems[index].isFavorite.toggle()
            
            if qrItems[index].isFavorite {
                updateWidgetImage(image: qrItems[index].image, name: qrItems[index].name, category: qrItems[index].category)
            } else {
                clearWidgetImage()
            }
            
            qrItems.sort { $0.isFavorite && !$1.isFavorite }
            saveQRItems(qrItems)
        }
    }
    
    private func clearWidgetImage() {
        let url = AppGroup.latestQRImageURL
        try? FileManager.default.removeItem(at: url)
        sharedDefaults?.removeObject(forKey: "widgetQRName")
        sharedDefaults?.removeObject(forKey: "widgetQRCategory")
        
        DispatchQueue.main.async {
            if self.isWidgetPrivateMode == true {
                self.isWidgetPrivateMode = false
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func updateWidgetImage(image: UIImage, name: String, category: QRCategory) {
        let url = AppGroup.latestQRImageURL
        let safeSize = CGSize(width: 400, height: 400)
        let smallImage = resizeImage(image: image, targetSize: safeSize)
        
        if let data = smallImage.pngData() {
            try? data.write(to: url)
        }
        
        sharedDefaults?.set(name, forKey: "widgetQRName")
        sharedDefaults?.set(category.rawValue, forKey: "widgetQRCategory")
        sharedDefaults?.synchronize()

        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func deleteItem(id: UUID) {
        qrItems.removeAll(where: { $0.id == id })
        saveQRItems(qrItems)
    }
}
