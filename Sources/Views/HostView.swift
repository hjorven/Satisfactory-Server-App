import SwiftUI

struct HostView: View {
    @Environment(ServerStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                let h = store.host
                if h == nil {
                    GlassCard { Text("Keine Host-Daten.").foregroundStyle(.secondary) }
                }
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SYSTEM").font(.caption2).foregroundStyle(.secondary)
                        if let u = h?.uptimeSec { StatusRow(label: "Uptime", value: uptime(u)) }
                        if let n = h?.cpuCount { StatusRow(label: "CPU-Kerne", value: "\(n)") }
                        if let l1 = h?.load1 {
                            StatusRow(label: "Load (1/5 min)", value: "\(l1) / \(h?.load5 ?? 0)")
                        }
                    }
                }
                if let t = h?.memTotalMB, let a = h?.memAvailMB, t > 0 {
                    let used = t - a
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ARBEITSSPEICHER").font(.caption2).foregroundStyle(.secondary)
                            ProgressView(value: max(0, used), total: t) {
                                HStack {
                                    Text("\(Int(used)) / \(Int(t)) MB")
                                    Spacer()
                                    Text("\(Int(used / t * 100))%")
                                }
                                .font(.caption).foregroundStyle(.secondary)
                            }
                            .tint(used / t > 0.9 ? .orange : .green)
                        }
                    }
                }
                if let dt = h?.diskTotalGB, let du = h?.diskUsedGB, dt > 0 {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SPEICHERPLATZ").font(.caption2).foregroundStyle(.secondary)
                            ProgressView(value: max(0, du), total: dt) {
                                HStack {
                                    Text("\(fmt(du)) / \(fmt(dt)) GB")
                                    Spacer()
                                    Text("\(fmt(h?.diskFreeGB ?? 0)) GB frei")
                                }
                                .font(.caption).foregroundStyle(.secondary)
                            }
                            .tint((h?.diskFreeGB ?? 99) < 5 ? .red : .green)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("System")
        .task { await store.fetchHost() }
        .refreshable { await store.fetchHost() }
    }

    private func uptime(_ s: Double) -> String {
        let total = Int(s)
        let d = total / 86400, h = (total % 86400) / 3600, m = (total % 3600) / 60
        return d > 0 ? "\(d) d \(h) h" : "\(h) h \(m) min"
    }
    private func fmt(_ v: Double) -> String { String(format: "%.1f", v) }
}
