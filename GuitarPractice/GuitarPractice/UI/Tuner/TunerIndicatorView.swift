import SwiftUI

struct TunerIndicatorView: View {
    let centsOffset: Double
    let isActive: Bool

    private var indicatorColor: Color {
        let absCents = abs(centsOffset)
        if absCents < 5 { return .green }
        if absCents < 15 { return .yellow }
        if absCents < 30 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: Theme.smallSpacing) {
            // Cents bar
            GeometryReader { geometry in
                let width = geometry.size.width
                let center = width / 2
                let markerOffset = isActive ? (centsOffset / 50.0) * (width / 2) : 0

                ZStack {
                    // Track background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 6)

                    // Tick marks
                    ForEach([-50, -25, 0, 25, 50], id: \.self) { tick in
                        let x = center + (Double(tick) / 50.0) * (width / 2)
                        Rectangle()
                            .fill(tick == 0 ? Color.primary.opacity(0.5) : Color.secondary.opacity(0.3))
                            .frame(width: tick == 0 ? 2 : 1, height: tick == 0 ? 20 : 12)
                            .position(x: x, y: geometry.size.height / 2)
                    }

                    // Marker needle
                    if isActive {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(indicatorColor)
                            .frame(width: 4, height: 24)
                            .shadow(color: indicatorColor.opacity(0.5), radius: 4)
                            .position(x: center + markerOffset, y: geometry.size.height / 2)
                            .animation(.easeOut(duration: 0.08), value: centsOffset)
                    }
                }
            }
            .frame(height: 28)

            // Tick labels
            HStack {
                Text("-50")
                Spacer()
                Text("-25")
                Spacer()
                Text("0")
                Spacer()
                Text("+25")
                Spacer()
                Text("+50")
            }
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(.tertiary)

            // Flat / Sharp labels
            HStack {
                Text("Flat")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if isActive {
                    Text(centsLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(indicatorColor)
                }
                Spacer()
                Text("Sharp")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var centsLabel: String {
        let rounded = Int(centsOffset.rounded())
        if rounded == 0 { return "In tune" }
        return rounded > 0 ? "+\(rounded)¢" : "\(rounded)¢"
    }
}
