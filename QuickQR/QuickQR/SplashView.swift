import SwiftUI

// MARK: SplashView
struct SplashView: View {

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("AppIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .scaleEffect(appeared ? 1.0 : 0.8)
                    .opacity(appeared ? 1.0 : 0.0)

                Text("widgetQR")
                    .font(.system(size: 28, weight: .black, design: .default))
                    .kerning(1.2)
                    .opacity(appeared ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}

