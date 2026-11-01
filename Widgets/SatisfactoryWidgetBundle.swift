import WidgetKit
import SwiftUI

// MARK: - Daten

struct WidgetData {
    var reachable: Bool
    var running: Bool
    var cpu: Int?
    var ramMB: Int?
    var production: Int
    var consumption: Int
    var capacity: Int
    var tripped: Int
    var playersOnline: Int
    var playersTotal: Int

    static let placeholder = WidgetData(reachable: true, running: true, cpu: 12, ramMB: 760,
                                        production: 1200, consumption: 278, capacity: 1770,
                                        tripped: 0, playersOnline: 1, playersTotal: 2)
    static let unavailable = WidgetData(reachable: false, running: false, cpu: nil, ramMB: nil,
                                        production: 0, consumption: 0, capacity: 0,
                                        tripped: 0, playersOnline: 0, playersTotal: 0)
}

// Minimal-Decodables passend zur WebUI-API
private struct WOverview: Decodable {
    struct Power: Decodable { var production: Int; var consumption: Int; var capacity: Int; var tripped: Int }
    var running: Bool
    var cpu: Double?
    var ramMB: Double?
    var power: Power
}
private struct WPlayer: Decodable { var Online: Bool }

enum Fetcher {
    // Persönliches Ein-Server-Setup: Adressen fest hinterlegt (LAN zuerst, dann Tailscale).
    static let bases: [URL] = [
        URL(string: "http://192.168.178.99:3000")!,
        URL(string: "https://satisfactory-server.tail5c967f.ts.net")!
    ]

    static func fetch() async -> WidgetData {
        for base in bases {
            if let d = try? await load(base) { return d }
        }
        return .unavailable
    }

    private static func load(_ base: URL) async throws -> WidgetData {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 6
        cfg.waitsForConnectivity = false
        let session = URLSession(configuration: cfg)

        // Gast-Login (setzt Session-Cookie in dieser ephemeren Session)
        var login = URLRequest(url: base.appendingPathComponent("api/login/guest"))
        login.httpMethod = "POST"
        login.setValue("application/json", forHTTPHeaderField: "Content-Type")
        login.httpBody = Data("{}".utf8)
        _ = try await session.data(for: login)

        let (ovData, _) = try await session.data(from: base.appendingPathComponent("api/overview"))
        let ov = try JSONDecoder().decode(WOverview.self, from: ovData)

        var online = 0, total = 0
        if let (plData, _) = try? await session.data(from: base.appendingPathComponent("api/players")),
           let players = try? JSONDecoder().decode([WPlayer].self, from: plData) {
            total = players.count
            online = players.filter { $0.Online }.count
        }

        return WidgetData(reachable: true, running: ov.running,
                          cpu: ov.cpu.map { Int($0) }, ramMB: ov.ramMB.map { Int($0) },
                          production: ov.power.production, consumption: ov.power.consumption,
                          capacity: ov.power.capacity, tripped: ov.power.tripped,
                          playersOnline: online, playersTotal: total)
    }
}

// MARK: - Timeline

struct SatisEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct SatisProvider: TimelineProvider {
    func placeholder(in context: Context) -> SatisEntry { SatisEntry(date: .now, data: .placeholder) }
    func getSnapshot(in context: Context, completion: @escaping (SatisEntry) -> Void) {
        Task { completion(SatisEntry(date: .now, data: await Fetcher.fetch())) }
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SatisEntry>) -> Void) {
        Task {
            let data = await Fetcher.fetch()
            let next = Calendar.current.date(byAdding: .minute, value: 20, to: .now)!
            completion(Timeline(entries: [SatisEntry(date: .now, data: data)], policy: .after(next)))
        }
    }
}

// MARK: - Views

private let lime = Color(red: 0.72, green: 0.95, blue: 0.29)

struct SatisWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: SatisEntry
    private var d: WidgetData { entry.data }

    var body: some View {
        switch family {
        case .accessoryInline:       inlineView
        case .accessoryCircular:     circularView
        case .accessoryRectangular:  rectView
        case .systemSmall:           smallView.containerBg
        case .systemMedium:          mediumView.containerBg
        default:                     largeView.containerBg
        }
    }

    private var statusText: String { !d.reachable ? "OFFLINE" : (d.running ? "ONLINE" : "GESTOPPT") }
    private var statusColor: Color { !d.reachable ? .gray : (d.running ? lime : .red) }

    // Home: klein
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SATISFACTORY").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
            Text(statusText).font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(statusColor)
            Spacer(minLength: 0)
            Label("\(d.playersOnline)/\(d.playersTotal)", systemImage: "person.2.fill").font(.caption2)
            Label("\(d.consumption) / \(d.capacity) MW", systemImage: "bolt.fill").font(.caption2).foregroundStyle(lime)
            if d.tripped > 0 {
                Label("\(d.tripped) Ausfall", systemImage: "bolt.slash.fill").font(.caption2).foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // Home: mittel
    private var mediumView: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SATISFACTORY").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                Text(statusText).font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(statusColor)
                Label("\(d.playersOnline)/\(d.playersTotal) Spieler", systemImage: "person.2.fill").font(.caption)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 7) {
                row("bolt.fill", "\(d.production) MW", lime, "Erzeugung")
                row("powerplug.fill", "\(d.consumption) MW", .orange, "Verbrauch")
                if let c = d.cpu { row("cpu.fill", "\(c)%", .secondary, "CPU") }
                if let r = d.ramMB { row("memorychip.fill", "\(r) MB", .secondary, "RAM") }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // Home: groß
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SATISFACTORY SERVER").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                Spacer()
                Text(statusText).font(.headline.weight(.heavy)).foregroundStyle(statusColor)
            }
            Divider()
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                GridRow {
                    bigStat("Spieler", "\(d.playersOnline)/\(d.playersTotal)", "person.2.fill", lime)
                    bigStat("Erzeugung", "\(d.production)", "bolt.fill", lime)
                }
                GridRow {
                    bigStat("Verbrauch", "\(d.consumption)", "powerplug.fill", .orange)
                    bigStat("Kapazität", "\(d.capacity)", "battery.100", .secondary)
                }
                GridRow {
                    bigStat("CPU", d.cpu.map { "\($0)%" } ?? "–", "cpu.fill", .secondary)
                    bigStat("RAM", d.ramMB.map { "\($0) MB" } ?? "–", "memorychip.fill", .secondary)
                }
            }
            if d.tripped > 0 {
                Label("\(d.tripped) Stromausfall!", systemImage: "bolt.slash.fill")
                    .font(.caption.bold()).foregroundStyle(.red)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // Sperrbildschirm
    private var inlineView: some View {
        Label("\(statusText) · \(d.playersOnline) Spieler · \(d.consumption) MW", systemImage: "bolt.fill")
    }
    private var circularView: some View {
        Gauge(value: Double(d.consumption), in: 0...Double(max(d.capacity, 1))) {
            Image(systemName: "bolt.fill")
        } currentValueLabel: {
            Text("\(d.playersOnline)")
        }
        .gaugeStyle(.accessoryCircular)
    }
    private var rectView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(statusText, systemImage: d.running ? "server.rack" : "exclamationmark.triangle.fill")
                .font(.headline)
            Text("\(d.playersOnline)/\(d.playersTotal) Spieler · \(d.consumption)/\(d.capacity) MW")
                .font(.caption)
            if d.tripped > 0 { Text("⚠ \(d.tripped) Ausfall").font(.caption2) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Helper
    private func row(_ icon: String, _ value: String, _ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 16)
            Text(value).font(.caption.weight(.semibold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
    private func bigStat(_ label: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(.title3, design: .rounded).weight(.bold))
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

private extension View {
    var containerBg: some View {
        self.containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.10, green: 0.12, blue: 0.09),
                                    Color(red: 0.06, green: 0.07, blue: 0.05)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Widget & Bundle

struct SatisfactoryWidget: Widget {
    let kind = "SatisfactoryStatus"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SatisProvider()) { entry in
            SatisWidgetView(entry: entry)
        }
        .configurationDisplayName("Satisfactory Server")
        .description("Serverstatus, Spieler und Strom auf einen Blick.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct SatisfactoryWidgetBundle: WidgetBundle {
    var body: some Widget { SatisfactoryWidget() }
}
