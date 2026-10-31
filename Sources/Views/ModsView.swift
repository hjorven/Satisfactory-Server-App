import SwiftUI

struct ModsView: View {
    @Environment(ServerStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !store.isAdmin {
                    GlassCard {
                        Label("Nur für Admins. Unter Einstellungen mit dem Admin-Passwort anmelden.",
                              systemImage: "info.circle")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                } else if store.mods.isEmpty {
                    GlassCard { Text("Keine Mods gefunden.").foregroundStyle(.secondary) }
                } else {
                    GlassCard {
                        Label("\(store.mods.count) Mods installiert", systemImage: "puzzlepiece.extension.fill")
                            .font(.headline)
                    }
                    ForEach(store.mods) { m in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(m.name).font(.subheadline.weight(.semibold))
                                HStack {
                                    Text(m.type == "dir" ? "Ordner" : "Datei")
                                    Spacer()
                                    Text("\(String(format: "%.1f", m.sizeMB)) MB")
                                }
                                .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if let e = store.lastError {
                    Label(e, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote).foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Mods")
        .task { if store.isAdmin { await store.fetchMods() } }
        .refreshable { if store.isAdmin { await store.fetchMods() } }
    }
}
