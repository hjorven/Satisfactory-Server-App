import SwiftUI
import Charts

struct PowerView: View {
    @Environment(ServerStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if store.circuits.isEmpty {
                        GlassCard {
                            Text("Keine Stromdaten. Läuft der Server und ist FRM aktiv?")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(store.circuits) { c in
                            GlassCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Stromkreis #\(c.CircuitGroupID)").font(.headline)
                                        Spacer()
                                        if c.FuseTriggered {
                                            Label("Ausfall", systemImage: "bolt.slash.fill")
                                                .font(.caption.bold())
                                                .foregroundStyle(.red)
                                        }
                                    }
                                    Chart {
                                        BarMark(x: .value("Typ", "Erzeugung"), y: .value("MW", c.PowerProduction))
                                            .foregroundStyle(.green)
                                        BarMark(x: .value("Typ", "Verbrauch"), y: .value("MW", c.PowerConsumed))
                                            .foregroundStyle(.orange)
                                        BarMark(x: .value("Typ", "Kapazität"), y: .value("MW", c.PowerCapacity))
                                            .foregroundStyle(.blue)
                                    }
                                    .frame(height: 130)
                                    StatusRow(label: "Erzeugung", value: "\(Int(c.PowerProduction)) MW")
                                    StatusRow(label: "Verbrauch", value: "\(Int(c.PowerConsumed)) MW")
                                    StatusRow(label: "Kapazität", value: "\(Int(c.PowerCapacity)) MW")
                                    if let cap = c.BatteryCapacity, cap > 0 {
                                        StatusRow(label: "Akku", value: "\(Int(c.BatteryPercent ?? 0)) %")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .refreshable { await store.refresh() }
            .navigationTitle("Strom")
        }
    }
}
