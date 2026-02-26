import Foundation
import Combine
import UIKit


final class GridEditorState: ObservableObject {
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)

    private func prepareHaptics() {
        lightHaptic.prepare()
        mediumHaptic.prepare()
    }

    init() {
        prepareHaptics()
    }

    @Published private(set) var isEditing: Bool = false
    @Published private(set) var isMultiSelectMode: Bool = false
    @Published private(set) var selectedSwapItemID: UUID? = nil
    @Published private(set) var selectedItems: Set<UUID> = []
    @Published private(set) var lastSwappedIDs: Set<UUID> = []

    
    
    func markSwapped(_ ids: [UUID]) {
        lastSwappedIDs = Set(ids)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.lastSwappedIDs.removeAll()
        }
    }


    func toggleSelection(id: UUID) {
        if selectedItems.contains(id) {
            selectedItems.remove(id)
            if selectedItems.isEmpty {
                isMultiSelectMode = false
            }
        } else {
            selectedItems.insert(id)
        }
    }

    
    func enterMultiSelectMode(with id: UUID) {
        isMultiSelectMode = true
        selectedItems = [id]
    }

    
    func clearSwapSelection() {
        selectedSwapItemID = nil
    }
 
    
    func toggleEditing() {
        isEditing.toggle()
        clearSwapSelection()
        clearSelection()
    }
    
    func exitMultiSelectMode() {
        isMultiSelectMode = false
        selectedItems.removeAll()
    }


    func clearSelection() {
        selectedItems.removeAll()
        isMultiSelectMode = false
    }

    
    func handleSwapTap(
        tappedID: UUID,
        onSwap: (UUID, UUID) -> Void
    ) {
        // 1回目タップ（swap候補選択）
        guard let selectedID = selectedSwapItemID else {
            selectedSwapItemID = tappedID
            lightHaptic.impactOccurred()   //軽い haptic
            return
        }

        // 同じものをタップ → キャンセル
        if selectedID == tappedID {
            clearSwapSelection()
            return
        }

        // swap 実行
        onSwap(selectedID, tappedID)
        mediumHaptic.impactOccurred()
        clearSwapSelection()
    }

    
    /// 長押しで呼ぶ：複数選択モード開始
    func startMultiSelection(with id: UUID) {
            guard !isMultiSelectMode else { return }
            isMultiSelectMode = true
            selectedItems = [id]
        }

    
    /// 複数選択モード中のタップ
    func toggleMultiSelection(id: UUID) {
            guard isMultiSelectMode else { return }

            if selectedItems.contains(id) {
                selectedItems.remove(id)
            } else {
                selectedItems.insert(id)
            }
        }

        /// ✖︎ボタンなどで呼ぶ：複数選択モード終了
        func exitMultiSelection() {
            isMultiSelectMode = false
            selectedItems.removeAll()
        }
}
    
