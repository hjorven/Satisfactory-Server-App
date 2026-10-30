import SwiftUI

@main
struct SatisfactoryServerApp: App {
    @State private var store = ServerStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(.accentColor)
        }
    }
}
