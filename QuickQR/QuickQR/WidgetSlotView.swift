import SwiftUI

// MARK: WidgetSlot
struct WidgetSlotView: View {
    @ObservedObject var qrManager: QRManager
    @Binding var selectedItem: QRGridItemModel?
    @Binding var isShowing: Bool
    @Binding var originalBrightness: CGFloat
    
    // MARK: - 内部パーツ: 目のボタン
    private var privacyToggleButton: some View {
        Button {
            withAnimation(.spring()) {
                qrManager.isWidgetPrivateMode.toggle()
            }
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            Image(systemName: qrManager.isWidgetPrivateMode ? "eye.slash.fill" : "eye.fill")
                .renderingMode(.original)
                .font(.title2)
                .foregroundColor(qrManager.isWidgetPrivateMode ? .orange : .blue)
                .frame(width: 44, height: 44)
        }
    }
    
    var body: some View {
        // お気に入りがある場合のみ表示
        if let favoriteItem = qrManager.qrItems.first(where: { $0.isFavorite }) {
            VStack(alignment: .leading, spacing: 10) {
                Label("ウィジェット表示中", systemImage: "star.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)

                HStack(spacing: 15) {
                    Button {
                        if !qrManager.isWidgetPrivateMode {
                            // ボタンを押した「今」の明るさを保存してから、最大にする
                            self.originalBrightness = UIScreen.main.brightness
                            
                            withAnimation(.spring()) {
                                selectedItem = favoriteItem
                                isShowing = true
                                UIScreen.main.brightness = 0.85
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    } label: {
                        slotContent(item: favoriteItem)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(qrManager.isWidgetPrivateMode)
                    
                    // --- プライバシー切り替えボタン ---
                    privacyToggleButton
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(16)
                .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(favoriteItem.category.color.opacity(0.8), lineWidth: 2)
                    )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal)
        }
    }

    // --- 内部パーツ: メインコンテンツ ---
    private func slotContent(item: QRGridItemModel) -> some View {
        HStack(spacing: 15) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                
                if qrManager.isWidgetPrivateMode {
                    VStack(spacing: 4) {
                        Image(systemName: "eye.slash.fill")
                            .renderingMode(.original)
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                        
                        Text("非表示中")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.primary)
                            .fixedSize()
                    }
                } else {
                    Image(uiImage: item.image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(6)
                        .background(Color.white.cornerRadius(10))
                }
            }
            .frame(width: 60, height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(qrManager.isWidgetPrivateMode ? Color.orange.opacity(0.5) : item.category.color, lineWidth: 2)
            )

            // --- テキスト部分 ---
            VStack(alignment: .leading, spacing: 2) {
                Text(qrManager.isWidgetPrivateMode ? "プライバシーモード" : item.name)
                    .font(.headline)
                    .foregroundColor(qrManager.isWidgetPrivateMode ? .primary : .primary) 
                
                Text(item.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.category.color.opacity(0.1))
                    .foregroundColor(item.category.color)
                    .cornerRadius(4)
            }
            Spacer()
        }
    }
}
