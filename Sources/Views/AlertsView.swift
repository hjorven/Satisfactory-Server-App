import SwiftUI

struct AlertsView: View {
    @Environment(ServerStore.self) private var store
    @State private var cfg = AlertConfig(power: true, derail: true, playerJoin: true,
                                         playerLeave: true, serverDown: true, lowDisk: true, lowDiskGB: 5)
    @State private var loaded = false

    var body: some View {
        Form {
            if store.isAdmin {
                Section("Push über ntfy") {
                    Toggle("Stromausfall", isOn: $cfg.power)
                    Toggle("Zug entgleist", isOn: $cfg.derail)
                    Toggle("Spieler tritt bei", isOn: $cfg.playerJoin)
                    Toggle("Spieler verlässt", isOn: $cfg.playerLeave)
                    Toggle("Server gestoppt/abgestürzt", isOn: $cfg.serverDown)
                    Toggle("Wenig Speicherplatz", isOn: $cfg.lowDisk)
                    Stepper("Speicher-Schwelle: \(Int(cfg.lowDiskGB)) GB",
                            value: $cfg.lowDiskGB, in: 1...100, step: 1)
                }
                Section {
                    Button("Speichern") { Task { await store.saveAlertConfig(cfg) } }
                        .disabled(store.busyAction != nil)
                }
            } else {
                Section {
                    Text("Konfiguration nur für Admins. Verlauf ist unten sichtbar.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("Verlauf (letzte Alarme)") {
                if store.alertHistory.isEmpty {
                    Text("Noch keine Alarme.").font(.footnote).foregroundStyle(.secondary)
                } else {
                    ForEach(store.alertHistory) { a in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.message)
                            Text(time(a.time)).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let s = store.actionStatus { Section { Text(s).foregroundStyle(.green).font(.footnote) } }
            if let e = store.lastError { Section { Text(e).foregroundStyle(.red).font(.footnote) } }
        }
        .navigationTitle("Alarme")
        .task {
            await store.fetchAlerts()
            if let c = store.alertConfig, !loaded { cfg = c; loaded = true }
        }
        .refreshable { await store.fetchAlerts() }
    }

    private func time(_ ms: Double) -> String {
        let f = DateFormatter(); f.dateFormat = "dd.MM. HH:mm"
        return f.string(from: Date(timeIntervalSince1970: ms / 1000))
    }
}
