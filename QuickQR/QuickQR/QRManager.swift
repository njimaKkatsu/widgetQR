import SwiftUI
import WidgetKit
import Foundation
import Combine

// MARK: - モデル
struct QRGridItemModel: Identifiable, Equatable {
    let id: UUID
    let image: UIImage
    let category: QRCategory
    let name: String
    var isFavorite: Bool
    let qrContent: String

    init(id: UUID = UUID(), image: UIImage, category: QRCategory, name: String, isFavorite: Bool = false, qrContent: String = "") {
            self.id = id
            self.image = image
            self.category = category
            self.name = name
            self.isFavorite = isFavorite
            self.qrContent = qrContent
        }

    static func == (lhs: QRGridItemModel, rhs: QRGridItemModel) -> Bool {
        lhs.id == rhs.id
    }
}

struct EncodableQRItem: Codable {
    let id: String
    let name: String
    let category: String
    let fileName: String
    let isFavorite: Bool
    let qrContent: String
}

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
            
            //プライバシーモード切り替え時も名前とカテゴリーを維持
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
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }

    // ウィジェット用保存処理
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

        // ウィジェット連動
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
                // ✅ お気に入り登録時に名前と色をウィジェットへ送る
                updateWidgetImage(image: qrItems[index].image, name: qrItems[index].name, category: qrItems[index].category)
                print("✅ Widget updated with NEW favorite info")
            } else {
                clearWidgetImage()
                print("ℹ️ Favorite cleared.")
            }
            
            qrItems.sort { $0.isFavorite && !$1.isFavorite }
            saveQRItems(qrItems)
        }
    }
    
    private func clearWidgetImage() {
        let url = AppGroup.latestQRImageURL
        try? FileManager.default.removeItem(at: url)
        
        // 情報をリセット
        sharedDefaults?.removeObject(forKey: "widgetQRName")
        sharedDefaults?.removeObject(forKey: "widgetQRCategory")
        
        DispatchQueue.main.async {
            if self.isWidgetPrivateMode == true {
                self.isWidgetPrivateMode = false
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // ウィジェット更新用：名前とカテゴリーを保存するロジックを追加
    private func updateWidgetImage(image: UIImage, name: String, category: QRCategory) {
        let url = AppGroup.latestQRImageURL
        let safeSize = CGSize(width: 400, height: 400)
        let smallImage = resizeImage(image: image, targetSize: safeSize)
        
        //  画像の保存
        if let data = smallImage.pngData() {
            try? data.write(to: url)
        }
        
        // 名前とカテゴリーの保存 (AppGroup経由)
        sharedDefaults?.set(name, forKey: "widgetQRName")
        sharedDefaults?.set(category.rawValue, forKey: "widgetQRCategory")
        
        // 明示的に即時反映
        sharedDefaults?.synchronize()

        // リロードを通知
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // 削除用などはそのまま
    func deleteItem(id: UUID) {
        qrItems.removeAll(where: { $0.id == id })
        saveQRItems(qrItems)
    }
}
