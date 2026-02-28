# widgetQR (Project Name: QuickQR)

**「出したい時に即、出せる。」** ロック画面やホーム画面から、お気に入りのQRコードをウィジェットから一瞬で表示するiOSアプリです。

## 📸 スクリーンショット

| 1. プレビュー表示 | 2. ウィジェット連携 | 3. 自動切り抜き | 4. アプリ内一覧 |
| :---: | :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/7b029444-9385-48f8-aed0-3c190249ffcc" width="200"> |  <img src="https://github.com/user-attachments/assets/3da1960f-ff9b-4c12-9cbf-e8f1f30c4aa5" width="200">  | <img src="https://github.com/user-attachments/assets/3bc498d3-fb43-41a8-b4e1-6ccab74d84b8" width="200"> |<img src="https://github.com/user-attachments/assets/41b784eb-5de2-43e0-ab5d-32c0a960e18b" width="200">|

## ✨ 主な機能
- **ロック画面ウィジェット**: iOS 16以降のロック画面から直接QRコードを起動。
- **ホーム画面ウィジェット**: よく使うQRを常に配置可能。
- **自動切り抜き**:画像や写真のQRコードを自動で検知、切り抜き。
- **グリッド管理**: 複数のQRコードを美しく整理して管理。
- **SwiftUI & WidgetKit**: 最新のフレームワークを使用したスムーズな動作。

## 🛠 技術スタック
- **Language**: Swift 6.0
- **Framework**: SwiftUI / WidgetKit (Lock & Home Screen)
- **Persistence (データ保存)**:
  - **JSON Serialization**: `FileManager` を活用し、QRコードのメタデータをローカルに保存。
  - **Shared Storage**: `UserDefaults (App Group)` により、アプリとウィジェット間のリアルタイムなデータ同期を実現。
  - **Image Archive**: `pngData` 形式でドキュメントディレクトリに効率的に保存。

## 💎 ユーザー体験（UX）へのこだわり

### 🧠 インテリジェントな画像処理
- **Vision Frameworkによる自動補正**: 
  斜めに撮影された写真でも `CIPerspectiveCorrection` を用いて、真正面から捉えた高精度なQRコードへ瞬時に変換。ユーザーが「手動で切り抜く」手間を完全に排除しました。
- **インテリジェント・クロッピング**: 
  QRコードの4角を検出し、視認性を高めるために1.05倍の余白を持たせて自動切り抜きを行います。

### 📱 実用性を追求した設計
- **目に優しいプレビュー**: 
  QRコード表示時の画面輝度をあえて最大ではなく「85%」に設定。読み取り精度を維持しつつ、暗所での眩しさを抑える配慮をしています。
- **プライバシー保護**: 
  ウィジェット上で内容を隠す「プライバシーモード」を搭載。公共の場でも安心して利用できます。
