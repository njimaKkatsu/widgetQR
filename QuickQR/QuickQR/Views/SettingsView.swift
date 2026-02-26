import SwiftUI
import UIKit

import SwiftUI

// MARK: SettingView
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userTheme") private var userTheme: Int = 0

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                helpSection
                aboutSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") { dismiss() }
                }
            }
        }
        .onAppear {
            if let theme = AppTheme(rawValue: userTheme) {
                applyTheme(theme)
            }
        }
    }
}



// MARK: - 各セクションの構成
private extension SettingsView {
    
    // 外観モード設定
    var appearanceSection: some View {
        Section {
            Picker("外観モード", selection: $userTheme) {
                Text("自動").tag(AppTheme.system.rawValue)
                Text("ライト").tag(AppTheme.light.rawValue)
                Text("ダーク").tag(AppTheme.dark.rawValue)
            }
            .pickerStyle(.menu)
            .onChange(of: userTheme) {
                if let theme = AppTheme(rawValue: userTheme) {
                    applyTheme(theme)
                }
            }
        } header: {
            Text("カスタマイズ")
        }
    }

    // ヒント（使い方ガイド）
    var helpSection: some View {
        Section(header: Text("ヒント")) {
            NavigationLink(destination: HowToUseWidgetView()) {
                Label("ウィジェットの使い方", systemImage: "square.dashed.inset.filled")
            }
            NavigationLink(destination: HowToUseMainView()) {
                Label("メイン画面の使い方", systemImage: "list.bullet.indent")
            }
            NavigationLink(destination: HowToUsePreviewView()) {
                Label("プレビュー画面でできること", systemImage: "qrcode.viewfinder")
            }
            NavigationLink(destination: HowToUseEditView()) {
                Label("編集モードでできること", systemImage: "square.and.pencil")
            }
        }
    }

    // アプリ情報
    var aboutSection: some View {
        Section(header: Text("アプリについて")) {
            HStack {
                Text("バージョン")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        }
    }
}
// ウィジェットの使い方ガイド画面
struct HowToUseWidgetView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                
                GuideSection(
                    title: "⭐️ お気に入りを表示する",
                    description: "プレビュー画面で「星マーク」をタップして、お気に入りに登録しましょう。メイン画面に新しくスロットができて、登録されたQRコードが自動的にウィジェットへ送られます。"
                )
                
                GuideSection(
                    title: "🏠 ホーム画面に追加する",
                    description: "ホーム画面の空いている場所を長押しし、左上の「＋」ボタンから『widgetQR』を探して追加してください。いつでも瞬時にコードを提示できます。ロック画面にも追加でき、ボタン一つでプレビューが表示できます。"
                )
                
                GuideSection(
                    title: "🔑 ロック画面に追加する",
                    description: "ロック画面の空いている場所を長押しし、下の「カスタマイズ」ボタンから『widgetQR』を探して追加してください。今後はボタン一つでお気に入りのプレビュー画面が表示できます。"
                )
                
                GuideSection(
                    title: "👁️ プライバシーを守る",
                    description: "人混みや外出先でQRコードを見せたくない時は、「ウィジェットを非表示にする」をオンにしましょう。お気に入りの設定はそのままで、一時的に隠すことができます。"
                )
                
                GuideSection(
                    title: "💡 活用アドバイス",
                    description: "ポイントカードやSNSの連絡先を登録しておくと便利です。ウィジェットをタップすれば、直接アプリのプレビュー画面へジャンプできます。"
                )
            }
            .padding()
        }
        .navigationTitle("ウィジェットの活用法")
    }
}

struct HowToUsePreviewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { 
                
                GuideSection(
                    title: "🔍 すぐにリンクへアクセス",
                    description: "一番左の「コンパス」ボタンを押すと、QRコードの内容をSafariで開きます。URLならそのままサイトへ、テキストなら検索がスムーズに行えます。"
                )
                
                GuideSection(
                    title: "📤 外部アプリへ送る",
                    description: "左から2番目の「共有」ボタンから、メールやSNSなどにQRコード画像を送信できます。友達にシェアしたい時に便利です。"
                )
                
                GuideSection(
                    title: "💾 アルバムに保存する",
                    description: "真ん中の「保存」ボタンをタップすると、iPhoneの「写真」アプリに画像を保存します。オフラインで見せたい時やバックアップにどうぞ。"
                )
                
                GuideSection(
                    title: "🌟 ウィジェットに表示する",
                    description: "一番右の「星」ボタンでお気に入りに登録しましょう。登録されたQRコードは、ホーム画面のウィジェットに自動で反映されます。"
                )
                
                GuideSection(
                    title: "💡 読み取りやすい工夫",
                    description: "プレビュー画面を開いている間は、QRコードが読み取りやすいように画面の明るさを最適化しています（画面を閉じると自動で戻ります）。"
                )
                
            }
            .padding()
        }
        .navigationTitle("プレビュー画面の活用")
    }
}

struct HowToUseMainView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                GuideSection(
                    title: "📸 QRコードを追加する",
                    description: "画面下のカメラアイコンから、お持ちのQRコードをアプリに取り込みましょう。名前とカテゴリーを分けて保存すれば、より分かりやすくなります。"
                )
                
                GuideSection(
                    title: "✏️ 自由に並べ替える（編集モード）",
                    description: "右上の「編集」をタップすると、QRコードを好きな順番に並べ替えることができます。よく使うものを一番上に置くのがおすすめです！"
                )
                
                GuideSection(
                    title: "🗑 まとめて整理（長押し）",
                    description: "QRコードを長押しすると、複数の項目を一気に選んで削除できます。増えすぎたコードも一気に整理可能です。ちなみに共有と保存も可能です(小声)。"
                )
                
                GuideSection(
                    title: "🔍 すばやく拡大（プレビュー）",
                    description: "使いたいQRコードをタップするだけで、画面いっぱいに表示されます。読み取りやすいように自動で画面が明るくなる設計です。"
                )
                
                GuideSection(
                    title: "⚙️ こだわりの設定",
                    description: "画面上部のスロットから、ウィジェットの非表示設定などを行えます。使いやすいようにカスタマイズしてみましょう。スロットはお気に入りが登録されていないと表示されないので注意してください！！"
                )
                
            }
            .padding()
        }
        .navigationTitle("メイン画面の使い方")
    }
}

struct HowToUseEditView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                GuideSection(
                    title: "🔁 かんたん並び替え",
                    description: "編集モード中に2つのQRコードを順番に選ぶだけで、場所をパッと入れ替えることができます。よく使うコードを上の方に整理してみましょう。"
                )
                
                GuideSection(
                    title: "🖼️ 画像のカスタマイズ",
                    description: "「この画像、もっと分かりやすくしたいな」と思ったら、QRコードを長押ししてみてください。いつでも新しい画像に差し替えることが可能です。"
                )
                
                GuideSection(
                    title: "✅ 設定を保存して終了",
                    description: "編集が終わったら、右下の「更新」ボタンを押してください。変更が保存され、編集モードに戻ります。メイン画面に戻りたいなら、画面右上の完了ボタンを押してくださいね！！"
                )
                
                GuideSection(
                    title: "💡 整理のコツ",
                    description: "お気に入りのQRコードは自動で一番左上に配置されます、ウィジェットからも素早くアクセスできてさらに便利になります！"
                )
            }
            .padding()
        }
        .navigationTitle("編集モードの活用")
    }
}

// 共通で使える見出しコンポーネント
struct GuideSection: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundColor(.blue)
            Text(description).font(.subheadline).foregroundColor(.primary)
            Divider()
        }
    }
}


func applyTheme(_ theme: AppTheme) {
    let scenes = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }

    let style: UIUserInterfaceStyle

    switch theme {
    case .light:
        style = .light
    case .dark:
        style = .dark
    case .system:
        style = UIScreen.main.traitCollection.userInterfaceStyle
    }

    scenes.forEach { scene in
        scene.windows.forEach { window in
            window.overrideUserInterfaceStyle = style
        }
    }
}
