import SwiftUI

@main
struct LeaseLensApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .tint(LeaseLensTheme.teal)
        }
    }
}
