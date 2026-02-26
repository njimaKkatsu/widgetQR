import SwiftUI

// MARK: - グリッド表示関連

// MARK: グリッド本体
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

// MARK: グリッドアイテム配置（行単位）
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
