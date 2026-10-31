import SwiftUI

struct RootView: View {
    @Environment(ServerStore.self) private var store

    var body: some View {
        Group {
            if store.baseURL == nil && store.connectionState != .connecting {
                ConnectView()
            } else {
                TabView {
                    OverviewView()
                        .tabItem { Label("Übersicht", systemImage: "gauge.with.dots.needle.67percent") }
                    PowerView()
                        .tabItem { Label("Strom", systemImage: "bolt.fill") }
                    PlayersView()
                        .tabItem { Label("Spieler", systemImage: "person.2.fill") }
                    ControlView()
                        .tabItem { Label("Steuerung", systemImage: "slider.horizontal.3") }
                    SettingsView()
                        .tabItem { Label("Einstellungen", systemImage: "gearshape") }
                }
            }
        }
        .task { await store.startup() }
    }
}
