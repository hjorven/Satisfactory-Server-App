import SwiftUI

/// Karte im Liquid-Glass-Look.
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

/// Kennzahl-Kachel.
struct MetricTile: View {
    let label: String
    let value: String
    var foot: String? = nil
    var tint: Color = .primary

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(label.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                if let foot {
                    Text(foot)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium).monospacedDigit()
        }
        .font(.subheadline)
    }
}
