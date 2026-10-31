import SwiftUI

struct FleetView: View {
    @Environment(ServerStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Züge (\(store.trains.count))", systemImage: "tram.fill").font(.headline)
                        if store.trains.isEmpty {
                            Text("Keine Züge.").font(.footnote).foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(store.trains.enumerated()), id: \.offset) { _, t in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(t.Name ?? "Zug").font(.subheadline.weight(.semibold))
                                        Spacer()
                                        if t.Derailed == true {
                                            Label("entgleist", systemImage: "exclamationmark.triangle.fill")
                                                .font(.caption.bold()).foregroundStyle(.red)
                                        }
                                    }
                                    if let s = t.Status, !s.isEmpty {
                                        Text(s).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Fahrzeuge (\(store.vehicles.count))", systemImage: "car.fill").font(.headline)
                        if store.vehicles.isEmpty {
                            Text("Keine Fahrzeuge.").font(.footnote).foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(store.vehicles.enumerated()), id: \.offset) { _, v in
                                HStack {
                                    Text(v.Name ?? v.ClassName ?? "Fahrzeug").font(.subheadline.weight(.semibold))
                                    Spacer()
                                    if v.AutoPilot == true {
                                        Label("Autopilot", systemImage: "steeringwheel")
                                            .font(.caption2).foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Drohnen (\(store.drones.count))", systemImage: "paperplane.fill").font(.headline)
                        if store.drones.isEmpty {
                            Text("Keine Drohnen.").font(.footnote).foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(store.drones.enumerated()), id: \.offset) { _, dr in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dr.Name ?? "Drohne").font(.subheadline.weight(.semibold))
                                    if let m = dr.CurrentFlyingMode, !m.isEmpty {
                                        Text(m).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Transport")
        .task { await store.fetchFleet() }
        .refreshable { await store.fetchFleet() }
    }
}
