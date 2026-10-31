import SwiftUI

struct PlayersView: View {
    @Environment(ServerStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    GlassCard {
                        HStack {
                            Label("\(store.onlineCount) online", systemImage: "person.fill")
                                .font(.headline)
                            Spacer()
                            Text("\(store.players.count) gesamt")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }

                    if store.players.isEmpty {
                        GlassCard {
                            Text("Keine Spielerdaten. Läuft der Server und ist FRM aktiv?")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(sortedPlayers) { p in
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Circle().fill(p.Online ? Color.green : Color.secondary)
                                            .frame(width: 10, height: 10)
                                        Text(p.Name).font(.headline)
                                        Spacer()
                                        if p.Dead == true {
                                            Label("tot", systemImage: "heart.slash.fill")
                                                .font(.caption.bold()).foregroundStyle(.red)
                                        } else {
                                            Text(p.Online ? "online" : "offline")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    if !p.Online, let ls = p.lastSeen {
                                        Text("zuletzt online: \(lastSeenText(ls))")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                    if let hp = p.PlayerHP {
                                        ProgressView(value: max(0, min(100, hp)), total: 100) {
                                            HStack {
                                                Text("HP")
                                                Spacer()
                                                Text("\(Int(hp))")
                                            }
                                            .font(.caption2).foregroundStyle(.secondary)
                                        }
                                        .tint(hp > 30 ? .green : .orange)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .refreshable { await store.pullRefresh() }
            .navigationTitle("Spieler")
        }
    }

    private var sortedPlayers: [Player] {
        store.players.sorted { ($0.Online ? 0 : 1, $0.Name) < ($1.Online ? 0 : 1, $1.Name) }
    }

    private func lastSeenText(_ ms: Double) -> String {
        let date = Date(timeIntervalSince1970: ms / 1000)
        let secs = Date().timeIntervalSince(date)
        if secs < 90 { return "gerade eben" }
        if secs < 3600 { return "vor \(Int(secs / 60)) min" }
        if secs < 86400 { return "vor \(Int(secs / 3600)) Std" }
        let f = DateFormatter(); f.dateFormat = "dd.MM. HH:mm"
        return f.string(from: date)
    }
}
