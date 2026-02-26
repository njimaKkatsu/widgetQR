import SwiftUI

// MARK: QRプレビュー
struct QRPreviewOverlay: View {
    let itemID: UUID
    @Binding var qrItems: [QRGridItemModel]
    @Binding var imagesToShare: [UIImage]
    @Binding var showShareSheet: Bool
    let onToggleFavorite: () -> Void
    let onClose: () -> Void
    
    @State private var appeared = false
    @State private var showSaveAlert = false
    
    

    // リストから現在の最新状態を見つける
    private var currentItem: QRGridItemModel? {
        qrItems.first(where: { $0.id == itemID })
    }

    var body: some View {
        ZStack {
            // --- 背景層 ---
            ZStack {
                BlurView(style: .systemUltraThinMaterialDark)
                    .opacity(appeared ? 1 : 0)
                Color.black.opacity(appeared ? 0.25 : 0)
            }
            .ignoresSafeArea()
            .onTapGesture { close() }
            
            // --- コンテンツ層 ---
            if let item = currentItem, appeared {
                VStack(spacing: 24) {
                    Image(uiImage: item.image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.7)
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 20)
                    
                    HStack(spacing: 24) {
                        if item.qrContent.lowercased().starts(with: "http"), let url = URL(string: item.qrContent) {
                                actionButton(systemName: "safari", iconColor: .blue) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        actionButton(systemName: "square.and.arrow.up") {
                            imagesToShare = [item.image]
                            showShareSheet = true
                        }
                        actionButton(systemName: "arrow.down.to.line") {
                            UIImageWriteToSavedPhotosAlbum(item.image, nil, nil, nil)
                            showSaveAlert = true
                        }
                        actionButton(
                            systemName: item.isFavorite ? "star.fill" : "star",
                            iconColor: item.isFavorite ? .yellow : .white
                        ) {
                            onToggleFavorite()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: 500)
                // .drawingGroup()　一旦コメントアウト
                .transition(
                    .asymmetric(
                        insertion: .identity,
                        removal: .opacity
                            .combined(with: .scale(scale: 0.5))
                            .combined(with: .offset(y: 100))
                    )
                )
                .zIndex(1)
                .id(itemID)
            }
        }
        .onAppear {
            // springアニメーション
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .alert("保存しました", isPresented: $showSaveAlert) {
                    Button("OK", role: .cancel) {}
                }
    }

    //close メソッド
    private func close() {
        withAnimation(.easeOut(duration: 0.2)) {
            appeared = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onClose()
        }
    }

    private func actionButton(systemName: String, iconColor: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 60, height: 60)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
}

