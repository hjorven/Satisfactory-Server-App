import SwiftUI

struct SavesView: View {
    @Environment(ServerStore.self) private var store
    @State private var toLoad: SaveGame?
    @State private var toDelete: SaveGame?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !store.isAdmin {
                    hintCard("Nur für Admins. Unter Einstellungen mit dem Admin-Passwort anmelden.")
                } else if !store.gameAuthed {
                    hintCard("Spielstände brauchen den Satisfactory-Spiel-Admin. Unter Einstellungen das Spiel-Admin-Passwort eingeben.")
                } else if store.saves.isEmpty {
                    GlassCard { Text("Keine Spielstände gefunden.").foregroundStyle(.secondary) }
                } else {
                    ForEach(store.saves) { s in saveCard(s) }
                }

                if let s = store.actionStatus {
                    Label(s, systemImage: "checkmark.circle.fill")
                        .font(.footnote).foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let e = store.lastError {
                    Label(e, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote).foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Spielstände")
        .task { if store.isAdmin && store.gameAuthed { await store.fetchSaves() } }
        .refreshable { await store.fetchSaves() }
        .confirmationDialog("Spielstand laden? Der aktuelle Fortschritt wird ersetzt.",
                            isPresented: binding($toLoad), presenting: toLoad) { s in
            Button("Laden", role: .destructive) { Task { await store.loadSave(s.saveName) } }
            Button("Abbrechen", role: .cancel) {}
        }
        .confirmationDialog("Spielstand löschen?",
                            isPresented: binding($toDelete), presenting: toDelete) { s in
            Button("Löschen", role: .destructive) { Task { await store.deleteSave(s.saveName) } }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private func saveCard(_ s: SaveGame) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(s.saveName).font(.headline)
                if let sess = s.sessionName, !sess.isEmpty { StatusRow(label: "Session", value: sess) }
                if let dt = s.saveDateTime, !dt.isEmpty { StatusRow(label: "Datum", value: dt) }
                if let d = s.playDurationSeconds { StatusRow(label: "Spielzeit", value: duration(d)) }
                HStack {
                    Button { toLoad = s } label: {
                        Label("Laden", systemImage: "arrow.down.circle.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent).disabled(store.busyAction != nil)
                    Button(role: .destructive) { toDelete = s } label: {
                        Label("Löschen", systemImage: "trash").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass).disabled(store.busyAction != nil)
                }
            }
        }
    }

    private func hintCard(_ text: String) -> some View {
        GlassCard {
            Label(text, systemImage: "info.circle")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func duration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600, m = (Int(seconds) % 3600) / 60
        return h > 0 ? "\(h) h \(m) min" : "\(m) min"
    }

    private func binding(_ item: Binding<SaveGame?>) -> Binding<Bool> {
        Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } })
    }
}
