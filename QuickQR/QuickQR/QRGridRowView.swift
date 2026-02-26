import SwiftUI

// MARK: グリッドアイテム配置
struct QRGridRowView: View {
    let items: [QRGridItemModel]
    let selectedSwapItemID: UUID?
    let lastSwappedIDs: Set<UUID>
    let selectedItems: Set<UUID>
    let onItemTap: (QRGridItemModel) -> Void
    let onItemLongPress: (QRGridItemModel) -> Void
    let columns: Int

    var body: some View {
        HStack(spacing: 12) {
            ForEach(items) { item in
                QRGridItemView(
                    item: item,
                    isSwapSelected: selectedSwapItemID == item.id,
                    didSwap: lastSwappedIDs.contains(item.id),
                    isMultiSelected: selectedItems.contains(item.id),
                    onTap: { onItemTap(item) },
                    onLongPress: { onItemLongPress(item) }
                )
                // 各アイテムが均等な1/4幅
                .frame(maxWidth: .infinity)
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .zIndex(1)
            }

            if items.count < columns {
                            ForEach(0..<(columns - items.count), id: \.self) { _ in
                                Color.clear
                                    .frame(maxWidth: .infinity)
                            }
                        }
        }
        .padding(.horizontal, 4)
    }
}
