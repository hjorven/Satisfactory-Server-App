import SwiftUI

struct ServerSettingsView: View {
    @Environment(ServerStore.self) private var store
    @State private var autoPause = false
    @State private var autoSaveDisc = false
    @State private var interval: Double = 300
    @State private var loaded = false

    var body: some View {
        Form {
            if !store.isAdmin {
                Text("Nur für Admins. Unter Einstellungen mit dem Admin-Passwort anmelden.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else if !store.gameAuthed {
                Text("Spiel-Admin nötig: unter Einstellungen → Satisfactory-Spiel-Admin das Passwort eingeben.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                Section("Spiel") {
                    Toggle("Auto-Pause wenn niemand online", isOn: $autoPause)
                    Toggle("Speichern beim Verlassen", isOn: $autoSaveDisc)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Autosave-Intervall")
                            Spacer()
                            Text("\(Int(interval)) s").foregroundStyle(.secondary)
                        }
                        Slider(value: $interval, in: 30...1800, step: 30)
                    }
                }
                Section {
                    Button("Speichern") {
                        Task {
                            await store.saveSettings(ServerSettings(
                                autoPause: autoPause,
                                autoSaveOnDisconnect: autoSaveDisc,
                                autosaveInterval: interval))
                        }
                    }
                    .disabled(store.busyAction != nil)
                }
                if let s = store.actionStatus {
                    Section { Text(s).foregroundStyle(.green).font(.footnote) }
                }
                if let e = store.lastError {
                    Section { Text(e).foregroundStyle(.red).font(.footnote) }
                }
            }
        }
        .navigationTitle("Server-Einstellungen")
        .task {
            guard store.isAdmin && store.gameAuthed else { return }
            await store.fetchSettings()
            if let s = store.serverSettings, !loaded {
                autoPause = s.autoPause
                autoSaveDisc = s.autoSaveOnDisconnect
                interval = s.autosaveInterval
                loaded = true
            }
        }
    }
}
