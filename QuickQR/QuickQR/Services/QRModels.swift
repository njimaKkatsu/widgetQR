import SwiftUI

// MARK: - メインのデータ型
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

// MARK: - 保存用（エンコード用）のデータ型
struct EncodableQRItem: Codable {
    let id: String
    let name: String
    let category: String
    let fileName: String
    let isFavorite: Bool
    let qrContent: String
}
