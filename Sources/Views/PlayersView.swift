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

                    if let w = store.worldStats {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("WELT").font(.caption2).foregroundStyle(.secondary)
                                if let b = w.buildings { StatusRow(label: "Gebäude gesamt", value: "\(b)") }
                                if let d = w.passedDays { StatusRow(label: "Tag", value: "\(d)") }
                                if let pd = w.totalPlayDuration, !pd.isEmpty { StatusRow(label: "Spielzeit (Welt)", value: pd) }
                            }
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
                                    if let ms = p.onlineMs, ms > 0 {
                                        StatusRow(label: "Spielzeit (getrackt)", value: durationText(ms))
                                    }
                                    if let dm = p.distanceM, dm > 0 {
                                        StatusRow(label: "Distanz", value: distanceText(dm))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .refreshable { await store.pullRefresh(); await store.fetchWorldStats() }
            .navigationTitle("Spieler")
            .task { await store.fetchWorldStats() }
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

    private func durationText(_ ms: Double) -> String {
        let total = Int(ms / 1000)
        let h = total / 3600, m = (total % 3600) / 60
        if h > 0 { return "\(h) h \(m) min" }
        if m > 0 { return "\(m) min" }
        return "< 1 min"
    }

    private func distanceText(_ m: Double) -> String {
        m >= 1000 ? String(format: "%.1f km", m / 1000) : "\(Int(m)) m"
    }
}
