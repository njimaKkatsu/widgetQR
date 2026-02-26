import SwiftUI
import UIKit

// MARK: ポップアップ
struct PhotoPopup: View {
    @Binding var isPresented: Bool
    let previewImage: UIImage?
    let qrNotFound: Bool
    let onReselectPhoto: () -> Void
    let onSave: (UIImage, QRCategory, String) -> Void
    let editingItem: QRGridItemModel?
    let onDelete: (() -> Void)?
    let onReselectWithSource: (UIImagePickerController.SourceType) -> Void

    @State private var selectedCategory: QRCategory? = nil
    @State private var nameText: String = ""
    @State private var isNameEditing: Bool = false
    @State private var isSaving = false
    @State private var showDeleteAlert = false
    @State private var showDiscardAlert: Bool = false
    //キーボードの状態を管理
    @FocusState private var isTextFieldFocused: Bool
    //初期状態を保持する変数
    @State private var initialName: String
    @State private var initialCategory: QRCategory
    @State private var imageChanged: Bool = false
    
    init(isPresented: Binding<Bool>, previewImage: UIImage?, qrNotFound: Bool, onReselectPhoto: @escaping () -> Void, onReselectWithSource: @escaping (UIImagePickerController.SourceType) -> Void, onSave: @escaping (UIImage, QRCategory, String) -> Void, editingItem: QRGridItemModel?, onDelete: @escaping () -> Void) {
        self._isPresented = isPresented
        self.previewImage = previewImage
        self.qrNotFound = qrNotFound
        self.onReselectPhoto = onReselectPhoto
        self.onReselectWithSource = onReselectWithSource
        self.onSave = onSave
        self.editingItem = editingItem
        self.onDelete = onDelete
        
        // 現在の入力値
        let baseName = editingItem?.name ?? ""
        let baseCategory = editingItem?.category
        
        _selectedCategory = State(initialValue: baseCategory)
        _nameText = State(initialValue: baseName)
        _isNameEditing = State(initialValue: false)
        
        // 初期値を保存
        _initialName = State(initialValue: baseName)
        _initialCategory = State(initialValue: baseCategory ?? .other)
    }
    
    // 変更判定
    private var hasChanges: Bool {
        if editingItem == nil {
            // 新規作成時：画像がある、または名前・カテゴリをいじったら変更ありとみなす
            return previewImage != nil || !nameText.isEmpty || selectedCategory != .other || imageChanged
        } else {
            // 編集モード時：初期値と比較
            return nameText != initialName || selectedCategory != initialCategory || imageChanged
        }
    }

    var body: some View {
        ZStack {
            // 背景（外側タップ時の処理）
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if isTextFieldFocused {
                        isTextFieldFocused = false
                        isNameEditing = false
                    } else if hasChanges {
                        if !isSaving && !showDeleteAlert {
                            showDiscardAlert = true
                        }
                    } else {
                        // 何も変更がない場合のみ即座に閉じる
                        if !isSaving && !showDeleteAlert {
                            isPresented = false
                        }
                    }
                }
            VStack(spacing: 20) {
                Text("QRコードを編集")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black.opacity(0.6))
                // カテゴリーと名前入力
                inputSection

                // 画像プレビューと更新/再選択ボタン
                if let image = previewImage {
                    qrPreviewSection(image: image)
                    updateImageControlSection
                } else if qrNotFound {
                    qrNotFoundSection
                }

                // 保存・キャンセル・削除ボタン
                bottomActionSection
            }
            .padding()
            .frame(width: 300)
            .background(Color.white)
            .cornerRadius(16)
            .alert("QRコードを削除しますか？", isPresented: $showDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除する", role: .destructive) {
                    onDelete?()
                    isPresented = false
                }
            } message: {
                Text("この操作は元に戻せません。")
            }
            // 削除アラートの下あたりに追加
            .alert("編集内容を破棄しますか？", isPresented: $showDiscardAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("破棄して閉じる", role: .destructive) {
                    isPresented = false
                }
            } message: {
                Text("この操作は元に戻せません。")
            }
        }
    }
    

    // MARK: - Subsections

    private var inputSection: some View {
        VStack(spacing: 12) {
            // カテゴリー選択（既存）
            Menu {
                ForEach(QRCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: { Text(category.rawValue) }
                }
            } label: {
                selectableText(selectedCategoryLabel, color: selectedCategory?.color ?? .blue)
            }

            // --- 名前の表示・編集エリア ---
            VStack(spacing: 8) {
                // ラベル部分は常に表示
                Button {
                    // withAnimation を外す
                    isNameEditing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFieldFocused = true
                    }
                }label: {
                    let labelText = nameText.isEmpty ? "名前を編集" : "名前: \(nameText)"
                    selectableText(labelText, color: .blue)
                }

                // TextFieldの表示条件を「isNameEditing」だけに絞る
                if isNameEditing || (editingItem != nil && !initialName.isEmpty) {
                    TextField("例：会員証 / SNS / 定期券", text: $nameText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 4)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            // ユーザーが「完了」を押したときだけ閉じる
                            isTextFieldFocused = false
                            isNameEditing = false
                        }
                }
            }
        }
    }

    private func qrPreviewSection(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 180, height: 180)
            .padding(12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedCategory?.color ?? .gray, lineWidth: 8)
            )
    }

    private var updateImageControlSection: some View {
            let isEditing = editingItem != nil
            let themeColor = isEditing ? Color.blue : Color.gray
            
            return VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: isEditing ? "arrow.triangle.2.circlepath" : "photo.stack")
                    Text(isEditing ? "画像を更新" : "QRコードを再選択")
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(themeColor)
                .padding(.leading, 4)

                HStack(spacing: 12) {
                    // カメラボタン
                    Button {
                        onReselectWithSource(.camera)
                        imageChanged = true
                    } label: {
                        actionButtonLabel(title: "カメラ", icon: "camera.fill", color: themeColor, isPrimary: false)
                    }

                    // 写真ボタン
                    Button {
                        onReselectWithSource(.photoLibrary)
                        imageChanged = true
                    } label: {
                        actionButtonLabel(title: "写真", icon: "photo.on.rectangle.angled", color: themeColor, isPrimary: false)
                    }
                }
            }
            .padding(12)
            .background(themeColor.opacity(0.06))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeColor.opacity(0.15), lineWidth: 1))
        }

    private var bottomActionSection: some View {
            HStack(spacing: 12) {
                if editingItem != nil {
                    Button { showDeleteAlert = true } label: {
                        actionButtonLabel(title: "削除", icon: "trash", color: .red)
                    }
                } else {
                    Button { isPresented = false } label: {
                        actionButtonLabel(title: "戻る", color: .gray)
                    }
                }

                // 保存・更新ボタン
                Button {
                    guard !isSaving, let image = previewImage else { return }
                    isSaving = true
                    
                    let finalCategory = selectedCategory ?? .other
                    onSave(image, finalCategory, nameText)
                } label: {
                    // QRコードがないときはグレーにする
                    let buttonColor: Color = (previewImage == nil) ? .gray : .blue
                    actionButtonLabel(title: editingItem == nil ? "保存" : "更新", color: buttonColor, isPrimary: (previewImage != nil))
                }
                // 画像がない（QRが見つからない）ときはボタンを無効化
                .disabled(previewImage == nil || isSaving)
            }
        }

    private var qrNotFoundSection: some View {
        let isEditing = editingItem != nil
        let themeColor = isEditing ? Color.blue : Color.gray
        
        return VStack(spacing: 16) {
            // 警告メッセージ
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("QRコードが見つかりません")
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.red)

            // カメラと写真の選択ボタン
            HStack(spacing: 12) {
                Button { onReselectWithSource(.camera) } label: {
                    actionButtonLabel(title: "カメラ", icon: "camera.fill", color: themeColor, isPrimary: false)
                }
                
                Button { onReselectWithSource(.photoLibrary) } label: {
                    actionButtonLabel(title: "写真", icon: "photo.on.rectangle.angled", color: themeColor, isPrimary: false)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
    }
    // MARK: - Helper Components

    private func updateSourceButton(title: String, icon: String, source: UIImagePickerController.SourceType, color: Color) -> some View {
        Button { onReselectWithSource(source) } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12))
                Text(title).font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(color.gradient)
            .cornerRadius(8)
        }
    }

    private func actionButtonLabel(title: String, icon: String? = nil, color: Color, isPrimary: Bool = false) -> some View {
        HStack {
            if let icon = icon { Image(systemName: icon) }
            Text(title)
        }
        .font(.subheadline.bold())
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(isPrimary ? color : color.opacity(0.1))
        .foregroundColor(isPrimary ? .white : color)
        .cornerRadius(10)
    }

    private func selectableText(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.subheadline.bold())
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(color.opacity(0.08))
            .cornerRadius(8)
    }

    private var selectedCategoryLabel: String {
        selectedCategory?.rawValue ?? "カテゴリーを選択"
    }
}
