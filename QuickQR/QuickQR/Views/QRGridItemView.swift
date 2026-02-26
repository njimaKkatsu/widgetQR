import SwiftUI
import UIKit

// MARK: グリッドアイテム
struct QRGridItemView: View {
    let item: QRGridItemModel
    let isSwapSelected: Bool
    let didSwap: Bool
    let isMultiSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    // 複数選択モード
    @State private var isActivePress = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Image(uiImage: item.image)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .background(Color.white)

                    Group {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(item.category.color, lineWidth: 7)

                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(didSwap ? 0.9 : 0), lineWidth: 4)

                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isMultiSelected ? Color.blue : Color.clear, lineWidth: 7)
                    }
                    .overlay(alignment: .topTrailing) {
                        if item.isFavorite {
                            Image(systemName: "star.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundColor(.yellow)
                                .padding(5)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 1)
                                .padding([.top, .trailing], 2)
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // --- 浮遊感のエフェクト ---
                .scaleEffect(isActivePress ? 1.15 : (isMultiSelected || isSwapSelected ? 1.08 : 1.0))
                .shadow(
                    color: .black.opacity(isActivePress ? 0.4 : (isMultiSelected || isSwapSelected ? 0.3 : 0.1)),
                    radius: isActivePress ? 15 : (isMultiSelected || isSwapSelected ? 12 : 4),
                    y: isActivePress ? 10 : 0
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActivePress)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isMultiSelected)

                if isMultiSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white.opacity(0.8)))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .font(.title2)
                        .padding(6)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            Text(item.name.isEmpty ? "名称未設定" : item.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(isMultiSelected ? .blue : .primary)
                .opacity(isActivePress ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: isActivePress)
        }
        .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded {
                        onTap()
                    }
                )
                .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        self.isActivePress = pressing
                    }
                    if pressing {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }, perform: {
                    isActivePress = false
                    onLongPress()
                })
    }
}
