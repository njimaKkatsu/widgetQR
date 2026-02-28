# widgetQR (Project Name: QuickQR)

**「出したい時に即、出せる。」** ロック画面やホーム画面から、お気に入りのQRコードをウィジェットから一瞬で表示するiOSアプリです。

## 📸 スクリーンショット

| 1. ロック画面 | 2. ウィジェット | 3. アプリ内一覧 | 4. 自動切り抜き |
| :---: | :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/7b029444-9385-48f8-aed0-3c190249ffcc" width="200"> |  <img src="https://github.com/user-attachments/assets/3da1960f-ff9b-4c12-9cbf-e8f1f30c4aa5" width="200">  | <img src="https://github.com/user-attachments/assets/41b784eb-5de2-43e0-ab5d-32c0a960e18b" width="200"> |<img src="https://github.com/user-attachments/assets/3bc498d3-fb43-41a8-b4e1-6ccab74d84b8" width="200">|

## ✨ 主な機能
- **ロック画面ウィジェット**: iOS 16以降のロック画面から直接QRコードを起動。
- **ホーム画面ウィジェット**: よく使うQRを常に配置可能。
- **自動切り抜き**:画像や写真のQRコードを自動で検知、切り抜き。
- **グリッド管理**: 複数のQRコードを美しく整理して管理。
- **SwiftUI & WidgetKit**: 最新のフレームワークを使用したスムーズな動作。

## 🛠 技術スタック
- **Language**: Swift 6.0
- **Framework**: SwiftUI
- **Target**: WidgetKit (Lock Screen & Home Screen)
- **Data**: Persistence:

JSON Serialization: FileManager を使用して、QRコードのリストをJSON形式でローカルに保存。

UserDefaults (App Group): アプリとウィジェット間でのデータ共有（お気に入り設定やプライベートモードの状態）に使用。

Image Storage: QRコード画像は pngData としてアプリ専用のドキュメントディレクトリに直接保存。

## 🎨 デザインのこだわり
ウィジェットからアプリへ遷移する際のユーザー体験（UX）を重視し、シンプルかつ直感的なインターフェースを目指しました。
