import Foundation

// MARK: AppGroup
enum AppGroup {

    /// App Group Identifier
    static let id = "group.com.katzo.quickqr"

    /// App Group のコンテナURL
    static var containerURL: URL {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: id)
        else {
            fatalError("❌ AppGroup container が取得できません")
        }
        return url
    }

    /// 最新QR画像の保存先
    static var latestQRImageURL: URL {
        containerURL.appendingPathComponent("latest_qr.png")
    }
}

