import SwiftUI

// MARK: - 空状態に関するViewまとめ

// MARK: 空状態テキスト
struct EmptyTextView: View {
    var title: String = "QRコードがまだありません"
    var subtitle: String = "写真からQRコードを読み取り\n一覧に保存できます。"
    var maxWidth: CGFloat = 250
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: maxWidth)
    }
}

// MARK: 空状態ボックスQR
struct EmptyStateBoxView: View {
    var systemImageName: String = "qrcode"
    var iconSize: CGFloat = 64
    var boxWidth: CGFloat = 250
    var boxHeight: CGFloat = 250
    var title: String = "QRコードがまだありません"
    var subtitle: String = "写真からQRコードを読み取り\n一覧に保存できます。"

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                EmptyIconView(systemImageName: systemImageName, size: iconSize, color: .gray)
                EmptyTextView(title: title, subtitle: subtitle, maxWidth: boxWidth)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.top, 8)
                Spacer()
            }
            .frame(width: boxWidth, height: boxHeight)
        }
    }
}

// MARK: 空状態QR
struct EmptyIconView: View {
    var systemImageName: String = "qrcode"
    var size: CGFloat = 64
    var color: Color = .gray
    
    var body: some View {
        Image(systemName: systemImageName)
            .font(.system(size: size))
            .foregroundColor(color)
    }
}
