import SwiftUI

struct StrumPatternView: View {
    let pattern: String
    let currentSlot: Int
    let beatsPerMeasure: Int
    let subdivisions: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(pattern.enumerated()), id: \.offset) { index, char in
                slotView(index: index, char: char)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(Theme.mediumSpacing)
        .background(Color.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: Theme.largeCornerRadius))
    }

    @ViewBuilder
    private func slotView(index: Int, char: Character) -> some View {
        let isActive = index == currentSlot
        let isMuted = char == "d" || char == "u"
        let isRest = char == "."

        VStack(spacing: 4) {
            // Arrow icon
            Group {
                if isRest {
                    Color.clear
                        .frame(width: 20, height: 20)
                } else {
                    let isDown = char == "D" || char == "d"
                    Image(systemName: isMuted ? "xmark" : (isDown ? "chevron.down" : "chevron.up"))
                        .font(.system(size: isMuted ? 14 : 18, weight: isMuted ? .regular : .semibold))
                        .opacity(isMuted ? 0.4 : 1.0)
                        .frame(width: 20, height: 20)
                }
            }

            // Beat label
            Text(beatLabel(for: index))
                .font(.caption2)
                .fontWeight(isMainBeat(index) ? .semibold : .regular)
                .foregroundStyle(isMainBeat(index) ? .primary : .secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.categoryColor(.strumming).opacity(0.2))
            }
        }
        .animation(.easeInOut(duration: 0.1), value: currentSlot)
    }

    private func beatLabel(for index: Int) -> String {
        let mainBeat = (index / subdivisions) + 1
        let isOffbeat = (index % subdivisions) != 0
        return isOffbeat ? "&" : "\(mainBeat)"
    }

    private func isMainBeat(_ index: Int) -> Bool {
        (index % subdivisions) == 0
    }
}
