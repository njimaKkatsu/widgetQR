import SwiftUI
import UIKit

// MARK: 共有画面
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: ぼかし用
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIViewController(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: view拡張
extension View {
    @ViewBuilder
    func `if`<Content: View, Else: View>(_ condition: Bool, transform: (Self) -> Content, else: (Self) -> Else) -> some View {
        if condition {
            transform(self)
        } else {
            `else`(self)
        }
    }
}
