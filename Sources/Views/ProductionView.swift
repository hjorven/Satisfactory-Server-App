import SwiftUI

struct ProductionView: View {
    @Environment(ServerStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if active.isEmpty {
                    GlassCard {
                        Text("Keine aktive Produktion. Läuft der Server und ist FRM aktiv?")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(active) { item in card(item) }
                }
            }
            .padding()
        }
        .navigationTitle("Produktion")
        .task { await store.fetchProd() }
        .refreshable { await store.fetchProd() }
    }

    private var active: [ProdItem] {
        store.prodStats
            .filter { ($0.CurrentProd ?? 0) > 0 || ($0.CurrentConsumed ?? 0) > 0 }
            .sorted { ($0.CurrentProd ?? 0) > ($1.CurrentProd ?? 0) }
    }

    private func card(_ i: ProdItem) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(i.Name).font(.headline)
                    Spacer()
                    if let t = i.itemType { Text(t).font(.caption2).foregroundStyle(.secondary) }
                }
                if let p = i.CurrentProd, p > 0 {
                    StatusRow(label: "Produktion", value: "\(fmt(p)) / \(fmt(i.MaxProd ?? 0)) /min")
                    if let pct = i.ProdPercent {
                        ProgressView(value: min(100, max(0, pct)), total: 100) {
                            HStack { Text("Auslastung"); Spacer(); Text("\(Int(min(100, max(0, pct))))%") }
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .tint(.green)
                    }
                }
                if let c = i.CurrentConsumed, c > 0 {
                    StatusRow(label: "Verbrauch", value: "\(fmt(c)) / \(fmt(i.MaxConsumed ?? 0)) /min")
                }
            }
        }
    }

    private func fmt(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
