import SwiftUI
import UIKit
import WidgetKit

// MARK: 保存処理
func saveQRImageToAppGroup(_ image: UIImage) {
    // リサイズ処理（ウィジェット制限を回避）
    let targetSize = CGSize(width: 400, height: 400)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
    
    let resizedImage = renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
    }

    // App Group への書き込み
    let url = AppGroup.latestQRImageURL
    guard let data = resizedImage.pngData() else { return }
    
    do {
        try data.write(to: url, options: [.atomic])
        // ウィジェットの更新通知
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ Widget image saved successfully")
    } catch {
        print("❌ Widget image save failed: \(error)")
    }
}

// MARK: 画像からQRコードの文字列を抽出
func scanQRCode(from image: UIImage) -> String {
    guard let ciImage = CIImage(image: image) else { return "" }
    
    // QRコード検出器を作成
    let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    
    // 文字列を抽出
    let features = detector?.features(in: ciImage) as? [CIQRCodeFeature]
    return features?.first?.messageString ?? ""
}

// MARK: UI ヘルパー
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

// MARK: 共有画面（UIKitのUIActivityViewControllerをSwiftUIで使う）
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: 空状態
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


// MARK: ぼかし用
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: グリッド
struct StaticGrid: View {
    @Binding var items: [QRGridItemModel]
    let selectedSwapItemID: UUID?
    let lastSwappedIDs: Set<UUID>
    let selectedItems: Set<UUID>
    let onItemTap: (QRGridItemModel) -> Void
    let onItemLongPress: (QRGridItemModel) -> Void
    let columns: Int

    var body: some View {
        VStack(spacing: 16) {
            let rows = stride(from: 0, to: items.count, by: columns).map {
                Array(items[$0..<min($0 + columns, items.count)])
            }

            ForEach(rows.indices, id: \.self) { index in
                QRGridRowView(
                    items: rows[index],
                    selectedSwapItemID: selectedSwapItemID,
                    lastSwappedIDs: lastSwappedIDs,
                    selectedItems: selectedItems,
                    onItemTap: onItemTap,
                    onItemLongPress: onItemLongPress,
                    columns: columns
                )
            }
        }
    }
}




// MARK: メイン構造
struct MainScreen: View {
    
    @AppStorage("userTheme") private var userTheme: Int = 0

    @State private var showPhotoPicker = false
    @State private var showPhotoPopup = false
    @State private var selectedImage: UIImage?
    @State private var croppedQRImage: UIImage?
    @State private var qrNotFound = false
    @State private var selectedQRItem: QRGridItemModel?
    @State private var showQRPreview = false
    
    @State private var showMultiSaveAlert = false
    //以下追加機能
    @State private var originalBrightness: CGFloat = UIScreen.main.brightness
    
    @State private var imagesToShare: [UIImage] = []
    @State private var showShareSheet = false

    //グリッド編集用
    @State private var showDeleteAlert = false
    //GridEditorStateから読み込み
    @StateObject private var editorState = GridEditorState()
    //QRManagerから読み込み
    @StateObject private var qrManager = QRManager()
    //編集モード
    @State private var editingItem: QRGridItemModel? = nil
    @State private var nameText: String = ""
    @State private var selectedCategory: QRCategory = .other
    @State private var liftingItemID: UUID? = nil
    
    //カメラ用
    @State private var showSourceSelection = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    
    //設定用
    @State private var showSettings = false
    
    //保存通知
    @State private var showSuccessToast = false
    @State private var toastMessage = ""

    //共有
    func shareImages(_ images: [UIImage]) {
        print("shareImages called with \(images.count) images")
            for (i, img) in images.enumerated() {
                print("Image \(i): size = \(img.size)")
            }
            guard !images.isEmpty else { return }
        imagesToShare = images
        showShareSheet = true
    }
    
    //スワップアイテム
    func swapItems(id1: UUID, id2: UUID) {
        guard
            let index1 = qrManager.qrItems.firstIndex(where: { $0.id == id1 }),
            let index2 = qrManager.qrItems.firstIndex(where: { $0.id == id2 }),
            index1 != index2
        else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            qrManager.qrItems.swapAt(index1, index2)
        }
        
        qrManager.saveQRItems(qrManager.qrItems)
    }

    //削除アイテム
    func deleteSelectedItems() {
        let idsToDelete = editorState.selectedItems

        // 削除前に対象画像ファイルを削除
        for id in idsToDelete {
            let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("\(id).png")
            try? FileManager.default.removeItem(at: imageURL)
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            qrManager.qrItems.removeAll { idsToDelete.contains($0.id) }
        }

        // 永続保存
        qrManager.saveQRItems(qrManager.qrItems)

        editorState.exitMultiSelectMode()
    }
    
    // 編集モード解除
    private func prepareForNewScan() {
        self.editingItem = nil
        self.nameText = ""
        self.selectedCategory = .other
        self.croppedQRImage = nil
    }
    
    // ディープリンクの処理
    private func handleDeepLink(_ url: URL) {
        if url.absoluteString == "quickqr://preview" {
            // ウィジェット（プレビュー）の処理
            if let latestItem = qrManager.qrItems.first(where: { $0.isFavorite }) ?? qrManager.qrItems.first {
                showQRPreview = false
                selectedQRItem = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring()) {
                        self.selectedQRItem = latestItem
                        self.showQRPreview = true
                        self.originalBrightness = UIScreen.main.brightness
                        UIScreen.main.brightness = 0.85
                    }
                }
            }
        } else if url.absoluteString == "quickqr://shared-image" {
            // AppGroupから読み込み
            let fileURL = AppGroup.latestQRImageURL
            
            if let imageData = try? Data(contentsOf: fileURL),
               let image = UIImage(data: imageData) {
                
                self.selectedImage = image
                
                if let cropped = cropQRCode(from: image) {
                    self.croppedQRImage = cropped
                    self.qrNotFound = false
                } else {
                    self.croppedQRImage = nil
                    self.qrNotFound = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring()) {
                        self.showPhotoPopup = true
                    }
                }
            }
        }
    }
    
    
    // MARK: 表示用にソートされたリスト
    private var sortedQRItems: [QRGridItemModel] {
        qrManager.qrItems.sorted { (lhs, rhs) in
            if lhs.isFavorite != rhs.isFavorite {
                return lhs.isFavorite && !rhs.isFavorite
            }
            return false
        }
    }
    //列数変更
    private var dynamicColumns: Int {
        // iPadかiPhoneかで列数を変える
        return UIDevice.current.userInterfaceIdiom == .pad ? 6 : 4
    }


    
    // MARK: Mainbody
    var body: some View {
        NavigationStack {
            ZStack {
                // 編集モード用 背景
                if editorState.isEditing && !qrManager.qrItems.isEmpty {
                                Color(.systemGroupedBackground)
                                    .ignoresSafeArea()
                                    .transition(.opacity)
                            } else {
                                // 通常時や空の状態は標準の背景色（白/黒）
                                Color(.systemBackground)
                                    .ignoresSafeArea()
                            }

                VStack(spacing: 0) {
                    headerView

                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // 【上部】専用スロットエリア
                            WidgetSlotView(qrManager: qrManager, selectedItem: $selectedQRItem,isShowing: $showQRPreview,
                                           originalBrightness: $originalBrightness)

                            // 全体のグリッド
                            VStack(alignment: .leading, spacing: 12) {
                                if qrManager.qrItems.count > 1 {
                                    Text("すべてのQRコード")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                }
                                
                                gridView
                            }
                        }
                        .padding(.vertical)
                    }
                    .overlay {
                        if qrManager.qrItems.isEmpty {
                            emptyState
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if editorState.isEditing {
                            editorState.clearSwapSelection()
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        bottomActionButton
                    }
                }
                .disabled(showPhotoPopup)
            }
            
            .onAppear {
                // すでにデータがあるなら、何度もロードしない
                if qrManager.qrItems.isEmpty {
                    qrManager.qrItems = qrManager.loadQRItems()
                }
            }
            .onChange(of: showShareSheet) {
                print("showShareSheet changed!")
            }
            //Widget遷移
            .onOpenURL { url in
                // ウィジェットからの特定のURLに反応
                if url.absoluteString == "quickqr://preview" {
                    
                    //  表示すべきアイテムを特定する
                    if let targetItem = qrManager.qrItems.first(where: { $0.isFavorite }) ?? qrManager.qrItems.first {
                        
                        // もし既に別のプレビューが開いていたら、一旦閉じる
                        showQRPreview = false
                        selectedQRItem = nil
                        
                        // ほんの少しだけ待ってから、新しいアイテムでプレビューを展開する
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring()) {
                                self.selectedQRItem = targetItem
                                self.showQRPreview = true
                                self.originalBrightness = UIScreen.main.brightness
                                UIScreen.main.brightness = 0.85
                            }
                        }
                    }
                }
            }
        }
        .alert("保存しました。", isPresented: $showMultiSaveAlert) {
            Button("OK", role: .cancel) {
                // 保存完了後に複数選択モードを終了する
                withAnimation(.easeInOut(duration: 0.25)) {
                    editorState.exitMultiSelectMode()
                }
            }
        } message: {
            Text("選択した全てのQRコードを\n写真ライブラリに保存しました。")
        }
        
        .alert("QRコードを削除します。", isPresented: $showDeleteAlert) {
            Button("はい", role: .destructive) {
                deleteSelectedItems()
            }
            Button("いいえ", role: .cancel) { }
        } message: {
            Text("この操作は元に戻せません。")
        }
        
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: pickerSource) { image in
                // 👈 ここを fixedUpright() に変更
                guard let fixedImage = image.fixedUpright() else { return }
                
                self.selectedImage = fixedImage
                
                if let cropped = cropQRCode(from: fixedImage) {
                    self.croppedQRImage = cropped
                    self.qrNotFound = false
                } else {
                    self.qrNotFound = true
                    self.croppedQRImage = nil
                }
                self.showPhotoPopup = true
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: imagesToShare)
        }
        
        .overlay(alignment: .bottomTrailing) {
            if editorState.isMultiSelectMode {
                multiSelectOverlay
            }
        }
        
        .overlay {
            popupOverlays
        }
        //保存、更新通知
        .overlay(alignment: .bottom) {
                    if showSuccessToast {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(toastMessage)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            Capsule()
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        )
                        .padding(.bottom, 100) // ボタンと被らないよう少し上に調整
                        /*.transition(
                                    .asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity), // 現れる時は下からフワッ
                                        removal: .opacity                                         // 消える時はその場でフワッ
                                    )
                                )*/
                        .zIndex(2) // ポップアップより手前か同等に
                    }
                }
    }
}

// MARK: 初期画面表示
private extension MainScreen {
    var emptyState: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // 画面中央にアイコン＋文字列の箱を置く
            EmptyStateBoxView(
                systemImageName: "qrcode",
                iconSize: 64,
                boxWidth: 250,
                title: "QRコードがまだありません",
                subtitle: "写真からQRコードを読み取り\n一覧に保存できます。"
            )
        }
    }
}

// MARK: header
private extension MainScreen {
    var headerView: some View {
            HStack (alignment: .center, spacing: 8){
                
                HStack(spacing: 0){
                    Text("widgetQR")
                        .font(.system(size: 18, weight: .black, design: .default))
                        .foregroundColor(.primary)
                    
                    Image("AppIconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .cornerRadius(8)
                }

                Spacer()
                //編集ボタン
                if editorState.isEditing {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.circle.fill")
                        Text("編集")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
                }

                if editorState.isMultiSelectMode {
                    Button {
                        editorState.exitMultiSelectMode()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                    }
                } else {
                    Button(editorState.isEditing ? "完了" : "編集") {
                        editorState.toggleEditing()
                    }
                    .font(.body)
                }
                
                Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            )
        }
}
// MARK: 追加ボタン
private extension MainScreen {
    var bottomActionButton: some View {
        Button {
            if editorState.isMultiSelectMode {
                showDeleteAlert = true
            } else {
                // 直接開かず、選択肢（Dialog）を出す
                showSourceSelection = true
            }
        } label: {
            Image(systemName: editorState.isMultiSelectMode ? "trash" : "camera.fill")
                .font(.title2)
                .padding()
                .background(editorState.isMultiSelectMode ? Color.red : Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(radius: 6)
                .opacity(editorState.isMultiSelectMode && editorState.selectedItems.isEmpty ? 0.4 : 1.0)
        }
        .disabled(editorState.isMultiSelectMode && editorState.selectedItems.isEmpty)
        .padding()
        .confirmationDialog("QRコードを取り込む", isPresented: $showSourceSelection, titleVisibility: .visible) {
                    Button("カメラで撮影") {
                        // 古いデータを確実にクリア
                        prepareForNewScan()
                        self.pickerSource = .camera
                        self.showPhotoPicker = true
                    }
                    Button("写真ライブラリから選択") {
                        // 古いデータを確実にクリアする
                        prepareForNewScan()
                        self.pickerSource = .photoLibrary
                        self.showPhotoPicker = true
                    }
                    Button("キャンセル", role: .cancel) { }
                }
    }
}


// MARK: グリッド画面
private extension MainScreen {
    var gridView: some View {
        StaticGrid(
            items: .constant(sortedQRItems),
            selectedSwapItemID: editorState.selectedSwapItemID,
            lastSwappedIDs: editorState.lastSwappedIDs,
            selectedItems: editorState.selectedItems,
            onItemTap: { item in
                // 複数選択モード中 → 選択切り替えのみ
                if editorState.isMultiSelectMode {
                    editorState.toggleSelection(id: item.id)
                    return
                }

                // 編集モード → swap
                if editorState.isEditing {
                    editorState.handleSwapTap(
                        tappedID: item.id,
                        onSwap: swapItems
                    )
                    return
                }

                // 通常 → プレビュー
                selectedQRItem = item
                originalBrightness = UIScreen.main.brightness
                UIScreen.main.brightness = 0.85
                showQRPreview = true
            },

            onItemLongPress: { item in
                if editorState.isEditing {
                    
                    editorState.clearSwapSelection()
                    
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    // 編集モード中の長押し：編集用ポップアップを表示
                    self.editingItem = item
                    self.selectedImage = item.image
                    self.croppedQRImage = item.image
                    self.nameText = item.name
                    self.selectedCategory = item.category
                    self.showPhotoPopup = true
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                self.showPhotoPopup = true
                            }
                        } else {
                            editorState.enterMultiSelectMode(with: item.id)
                        }
            },
            
            columns: dynamicColumns
        )
        .padding()
    }
}


// MARK: ポップアップの呼び出し口
private extension MainScreen {
    @ViewBuilder
    var popupOverlays: some View {
        //  新しく画像を追加する時のポップアップ
        if showPhotoPopup {
            PhotoPopup(
                isPresented: $showPhotoPopup,
                previewImage: croppedQRImage,
                qrNotFound: qrNotFound,
                onReselectPhoto: {
                        showPhotoPicker = true
                    },
                    onReselectWithSource: { source in
                        // 編集モード用：ボタンから渡されたソース（カメラor写真）をセットして起動
                        self.pickerSource = source
                        self.showPhotoPicker = true
                    },
                onSave: { image, category, name in
                    let scannedText = scanQRCode(from: image)
                    if let item = editingItem {
                        // ---既存アイテムの更新 (編集モード) ---
                        if let index = qrManager.qrItems.firstIndex(where: { $0.id == item.id }) {
                            withAnimation {
                                qrManager.qrItems[index] = QRGridItemModel(
                                    id: item.id,
                                    image: image,
                                    category: category,
                                    name: name,
                                    isFavorite: item.isFavorite,
                                    qrContent: scannedText
                                )
                            }
                            
                            // お気に入りアイテムを編集した場合は、ウィジェット画像も更新
                            if item.isFavorite {
                                qrManager.saveQRImageToAppGroup(image: image, name: name, category: category)
                            }
                        }
                    } else {
                        // --- 新しいアイテムの作成 ---
                        let newItem = QRGridItemModel(
                            image: image,
                            category: category,
                            name: name,
                            isFavorite: false,
                            qrContent: scannedText
                        )
                        
                        withAnimation {
                            qrManager.qrItems.append(newItem)
                        }
                        
                        // 新規追加時は、最新画像をウィジェットに送る
                        qrManager.saveQRImageToAppGroup(image: image, name: name, category: category)
                    }
                    
                    // --- 共通の保存処理 ---
                    qrManager.saveQRItems(qrManager.qrItems)
                    
                    // 通知ロジック
                    toastMessage = (self.editingItem == nil) ? "保存しました" : "更新しました"
                    
                    // 編集状態のリセット
                    self.editingItem = nil
                    self.showPhotoPopup = false
                    
                    //アニメーション付きで通知
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSuccessToast = true
                    }

                    // 触覚フィードバック（微振動）
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    // 1.5秒後に自動で消す
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showSuccessToast = false
                        }
                    }
                },
                editingItem: self.editingItem,
                onDelete: {
                        if let item = editingItem {
                            qrManager.deleteItem(id: item.id)
                            self.editingItem = nil
                        }
                    }
            )
            .onChange(of: showPhotoPopup) { oldValue, newValue in
                if newValue == false {
                    self.editingItem = nil
                    self.nameText = ""
                }
            }
        }

        // 既存のQRコードを表示するプレビュー
        if showQRPreview, let item = selectedQRItem {
            QRPreviewOverlay(
                itemID: item.id,
                qrItems: $qrManager.qrItems,
                imagesToShare: $imagesToShare,
                showShareSheet: $showShareSheet,
                onToggleFavorite: {
                    qrManager.toggleFavorite(id: item.id)
                },
                onClose: {
                    // プレビュー画面自体の存在を消す
                    showQRPreview = false
                    selectedQRItem = nil
                    
                    //画面の明るさを戻す
                    UIScreen.main.brightness = originalBrightness
                    
                    //0.1秒ほど待ってからリストを並び替える
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            qrManager.qrItems.sort { $0.isFavorite && !$1.isFavorite }
                        }
                        // 並び替えた結果を保存
                        qrManager.saveQRItems(qrManager.qrItems)
                    }
                }
            )
        }
    }
}

// MARK: 複数選択
private extension MainScreen {
    var multiSelectOverlay: some View {
        HStack(spacing: 16) {
          
            // 共有
            Button {
                imagesToShare = editorState.selectedItems.compactMap { id in
                    qrManager.qrItems.first(where: { $0.id == id })?.image
                }
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .padding(12)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            
            // 保存
            Button {
                for itemId in editorState.selectedItems {
                    if let item = qrManager.qrItems.first(where: { $0.id == itemId }) {
                        // 1. フォトライブラリに保存
                        UIImageWriteToSavedPhotosAlbum(item.image, nil, nil, nil)
                        
                        // 2. Documents フォルダに永続保存
                        qrManager.saveQRItems(qrManager.qrItems)
                        
                        // 3. App Group に最新画像保存（ウィジェット用）
                        saveQRImageToAppGroup(item.image)
                    }
                }
                
                showMultiSaveAlert = true
                
                editorState.clearSelection()
            } label: {
                Image(systemName: "arrow.down.to.line")
                    .font(.subheadline)
                    .padding(12)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }

        }
        .padding()
    }
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

// MARK: 画像の向き制御
extension UIImage {
    func fixOrientation() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }

        var transform = CGAffineTransform.identity

        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }

        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }

        guard let cgImage = self.cgImage,
              let colorSpace = cgImage.colorSpace,
              let ctx = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                  bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0,
                                  space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else {
            return self
        }

        ctx.concatenate(transform)

        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        }

        guard let newCgImage = ctx.makeImage() else { return self }
        return UIImage(cgImage: newCgImage)
    }
}

