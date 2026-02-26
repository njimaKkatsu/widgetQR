import WidgetKit
import SwiftUI
import UIKit

// MARK: - Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let name: String
    let category: QRCategory
    let isPrivate: Bool
}

// MARK: - Provider
struct SimpleProvider: TimelineProvider {

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), image: UIImage(systemName: "qrcode"), name: "名称未設定", category: .other, isPrivate: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = createEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    // 共通のデータ取得ロジック
    private func createEntry() -> SimpleEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.katzo.quickqr")
        
        // 保存された名前とカテゴリーを読み込む
        let name = sharedDefaults?.string(forKey: "widgetQRName") ?? "名称未設定"
        let categoryRaw = sharedDefaults?.string(forKey: "widgetQRCategory") ?? "other"
        let category = QRCategory(rawValue: categoryRaw) ?? .other
        
        return SimpleEntry(
            date: Date(),
            image: loadQRImage(),
            name: name,
            category: category,
            isPrivate: checkPrivacyMode()
        )
    }

    private func loadQRImage() -> UIImage? {
        let url = AppGroup.latestQRImageURL
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }

    private func checkPrivacyMode() -> Bool {
        let sharedDefaults = UserDefaults(suiteName: "group.com.katzo.quickqr")
        return sharedDefaults?.bool(forKey: "isWidgetPrivateMode") ?? false
    }
}

// MARK: - Widget View
struct QuickQRWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: SimpleEntry
    
    var body: some View {
        Group {
            if entry.isPrivate && (family == .systemSmall || family == .systemMedium || family == .systemLarge) {
                VStack(spacing: 8) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: family == .systemSmall ? 30 : 44))
                        .foregroundColor(.orange.opacity(0.8))
                    Text("プライバシーモード中")
                        .font(.system(size: family == .systemSmall ? 10 : 14, weight: .bold))
                        .foregroundColor(.gray)
                }
            } else {
                switch family {
                case .systemSmall, .systemLarge:
                    qrOnlyView(image: entry.image)
                    
                case .systemMedium:
                    mediumSlotView(itemImage: entry.image)

                case .accessoryRectangular, .accessoryCircular, .accessoryInline:
                    accessoryView(family: family)
                    
                default:
                    Text("widetQR")
                }
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
        .widgetURL(URL(string: "quickqr://preview"))
    }

    // --- QRコードのみ (Small / Large 用) ---
    private func qrOnlyView(image: UIImage?) -> some View {
        ZStack {
            if let image = image {
                Color.white
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(family == .systemLarge ? 24 : 8)
            } else {
                VStack {
                    Image(systemName: "qrcode").font(.largeTitle).foregroundColor(.gray)
                    Text("未設定").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    // --- 内部パーツ B: スロット風デザイン (Medium 用) ---
    private func mediumSlotView(itemImage: UIImage?) -> some View {
        HStack(spacing: 16) {
            // --- QRプレビュー枠 ---
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    // 画像がないときはグレー背景
                    .fill(itemImage == nil ? Color(.systemGray6) : entry.category.color.opacity(0.15))
                
                if let image = itemImage {
                    // QRコードがある場合
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(8)
                        .background(Color.white.cornerRadius(8))
                        .shadow(color: .black.opacity(0.1), radius: 2)
                } else {
                    // 未設定の場合のアイコンと文字
                    VStack(spacing: 4) {
                        Image(systemName: "qrcode")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("未設定")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 100, height: 100)

            // --- 右側：テキスト情報 ---
            VStack(alignment: .leading, spacing: 8) {
                if itemImage != nil {
                    // 通常時（お気に入りあり）
                    Text(entry.category.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(entry.category.color.opacity(0.2))
                        .foregroundColor(entry.category.color)
                        .cornerRadius(4)
                    
                    Text(entry.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("タップして\nプレビューを表示")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                } else {
                    // 未設定時（お気に入りなし）
                    Text("QRコード未登録")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("お気に入りに登録すると\nここに表示されます")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 0)
                    
                    Text("アプリを開いて設定")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 10)
            
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private func accessoryView(family: WidgetFamily) -> some View {
        if family == .accessoryRectangular {
            HStack(spacing: 8) {
                Image(systemName: "qrcode.viewfinder").font(.system(size: 26))
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.name).font(.system(size: 14, weight: .bold)).lineLimit(1)
                    Text("タップして表示").font(.system(size: 10)).opacity(0.8)
                }
            }
        } else {
            Image(systemName: "qrcode").font(.system(size: 20))
        }
    }
}
