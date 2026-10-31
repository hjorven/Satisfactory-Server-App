import SwiftUI

struct OverviewView: View {
    @Environment(ServerStore.self) private var store

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer(spacing: 0) {
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
                        MetricTile(label: "Spieler",
                                   value: "\(store.onlineCount)",
                                   foot: store.players.isEmpty ? nil : "\(store.players.count) gesamt",
                                   tint: store.onlineCount > 0 ? .green : .secondary)
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

                    if let s = store.session {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("SPIELWELT").font(.caption2).foregroundStyle(.secondary)
                                if let d = s.PassedDays {
                                    StatusRow(label: "Tag", value: "\(d)")
                                }
                                if let h = s.Hours, let m = s.Minutes {
                                    StatusRow(label: "Uhrzeit",
                                              value: "\(String(format: "%02d:%02d", h, m)) \(s.IsDay == true ? "☀️" : "🌙")")
                                }
                                if let pd = s.TotalPlayDurationText, !pd.isEmpty {
                                    StatusRow(label: "Spielzeit", value: pd)
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MEHR").font(.caption2).foregroundStyle(.secondary)
                            NavigationLink { MapView() } label: {
                                Label("Karte", systemImage: "map.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                            }
                            Divider()
                            NavigationLink { ProductionView() } label: {
                                Label("Produktion", systemImage: "chart.bar.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                            }
                            Divider()
                            NavigationLink { FleetView() } label: {
                                Label("Transport (Züge/Fahrzeuge)", systemImage: "tram.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                            }
                            Divider()
                            NavigationLink { HostView() } label: {
                                Label("System (Host/Speicher)", systemImage: "cpu.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                            }
                        }
                    }
                }
                }
                .padding()
            }
            .refreshable { await store.pullRefresh() }
            .navigationTitle("Übersicht")
            .overlay(alignment: .bottom) {
                if store.overview == nil && store.connectionState == .connecting {
                    ProgressView("Verbinde …").padding().glassEffect(in: .capsule)
                }
            }
        }
    }
}
