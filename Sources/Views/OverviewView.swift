import SwiftUI

struct OverviewView: View {
    @Environment(ServerStore.self) private var store

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let alerts = store.overview?.alerts, !alerts.isEmpty {
                        ForEach(alerts) { alert in
                            Label(alert.message, systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .glassEffect(.regular.tint(.red), in: .rect(cornerRadius: 16))
                        }
                    }

                    let ov = store.overview
                    LazyVGrid(columns: columns, spacing: 14) {
                        MetricTile(label: "Server",
                                   value: ov?.running == true ? "ONLINE" : "OFFLINE",
                                   foot: ov?.status,
                                   tint: ov?.running == true ? .green : .secondary)
                        MetricTile(label: "Simulation",
                                   value: ov?.paused == true ? "PAUSE" : (ov?.paused == false ? "AKTIV" : "–"),
                                   foot: ov?.session)
                        MetricTile(label: "CPU",
                                   value: ov?.cpu.map { "\(Int($0))%" } ?? "–")
                        MetricTile(label: "RAM",
                                   value: ov?.ramMB.map { "\(Int($0)) MB" } ?? "–")
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("STROMNETZ").font(.caption2).foregroundStyle(.secondary)
                            if let p = ov?.power {
                                StatusRow(label: "Erzeugung", value: "\(p.production) MW")
                                StatusRow(label: "Verbrauch", value: "\(p.consumption) MW")
                                StatusRow(label: "Kapazität", value: "\(p.capacity) MW")
                                StatusRow(label: "Stromkreise", value: "\(p.circuits)")
                                if p.tripped > 0 {
                                    Text("\(p.tripped) Ausfall/Ausfälle!")
                                        .font(.footnote.weight(.bold))
                                        .foregroundStyle(.red)
                                }
                            } else {
                                Text("Keine Daten").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .refreshable { await store.refresh() }
            .navigationTitle("Übersicht")
            .overlay(alignment: .bottom) {
                if store.overview == nil && store.connectionState == .connecting {
                    ProgressView("Verbinde …").padding().glassEffect(in: .capsule)
                }
            }
        }
    }
}
