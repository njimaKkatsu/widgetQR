import SwiftUI

// MARK: RootView
struct RootView: View {
    @State private var showSplash = true
    @State private var mainAppeared = false

    var body: some View {
        ZStack {
            MainScreen()
                .scaleEffect(mainAppeared ? 1 : 0.95)
                .opacity(mainAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.6), value: mainAppeared)

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                mainAppeared = true
                withAnimation(.easeOut(duration: 0.8)) {
                    showSplash = false
                }
            }
        }
    }
}
