import SwiftUI
import Charts

struct PowerView: View {
    @Environment(ServerStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let p = store.overview?.power {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Gesamt").font(.headline)
                                    Spacer()
                                    if p.tripped > 0 {
                                        Label("\(p.tripped) Ausfall", systemImage: "bolt.slash.fill")
                                            .font(.caption.bold()).foregroundStyle(.red)
                                    }
                                }
                                HStack(spacing: 16) {
                                    legend(.green, "Erzeugung", "\(p.production) MW")
                                    legend(.orange, "Verbrauch", "\(p.consumption) MW")
                                    Spacer()
                                }
                                historyChart
                                StatusRow(label: "Kapazität", value: "\(p.capacity) MW")
                                StatusRow(label: "Stromkreise", value: "\(p.circuits)")
                            }
                        }
                    } else {
                        GlassCard {
                            Text("Keine Stromdaten. Läuft der Server und ist FRM aktiv?")
                                .foregroundStyle(.secondary)
                        }
                    }

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
                .padding()
            }
            .refreshable { await store.pullRefresh() }
            .navigationTitle("Strom")
        }
    }

    // MARK: - Verlaufs-Diagramm

    private var historyChart: some View {
        Chart {
            ForEach(store.powerHistory) { s in
                AreaMark(x: .value("Zeit", s.time), y: .value("MW", s.production))
                    .foregroundStyle(.green.opacity(0.12))
                    .interpolationMethod(.catmullRom)
            }
            ForEach(store.powerHistory) { s in
                LineMark(x: .value("Zeit", s.time), y: .value("MW", s.production),
                         series: .value("Serie", "Erzeugung"))
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)
            }
            ForEach(store.powerHistory) { s in
                LineMark(x: .value("Zeit", s.time), y: .value("MW", s.consumption),
                         series: .value("Serie", "Verbrauch"))
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .chartYAxisLabel("MW")
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .frame(height: 190)
        .overlay {
            if store.powerHistory.count < 2 {
                Text("Sammle Verlaufsdaten …")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func legend(_ color: Color, _ title: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption2).foregroundStyle(.secondary)
                Text(value).font(.subheadline.bold())
            }
        }
    }
}
