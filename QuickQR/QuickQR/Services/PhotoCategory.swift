import SwiftUI

// MARK: QRCategory
enum QRCategory: String, CaseIterable, Identifiable {
    case transport = "交通系"
    case profile  = "SNS"
    case event    = "会員証"
    case other    = "その他"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .transport: return .red
        case .profile:  return .green
        case .event:    return .orange
        case .other:    return .gray
        }
    }
}

