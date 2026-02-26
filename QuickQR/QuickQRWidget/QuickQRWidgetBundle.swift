import WidgetKit
import SwiftUI
import UIKit

// MARK: Widgetメイン構造
@main
struct QuickQRWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickQRWidget()
    }
}

struct QuickQRWidget: Widget {
    let kind = "QuickQRWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: SimpleProvider()
        ) { entry in
            QuickQRWidgetView(entry: entry)
        }
        .configurationDisplayName("widgetQR")
        .description("保存したQRを表示します")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}


