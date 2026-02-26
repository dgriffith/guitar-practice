import SwiftUI

struct ScaleDiagramView: View {
    let scaleName: String
    let isActive: Bool

    private let numStrings = 6

    var body: some View {
        VStack(spacing: 4) {
            Text(scaleName)
                .font(.headline)
                .fontWeight(isActive ? .bold : .medium)
                .foregroundStyle(isActive ? .primary : .secondary)

            if let position = ScaleLibrary.position(for: scaleName) {
                diagramView(position: position)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 100, height: 90)
                    .overlay {
                        Text("?")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .opacity(isActive ? 1.0 : 0.5)
    }

    @ViewBuilder
    private func diagramView(position: ScalePosition) -> some View {
        let stringSpacing: CGFloat = 14
        let fretSpacing: CGFloat = 18
        let gridWidth = CGFloat(numStrings - 1) * stringSpacing
        let gridHeight = CGFloat(position.fretCount) * fretSpacing
        let topMargin: CGFloat = 14
        let scaleRadius: CGFloat = 5
        let rootRadius: CGFloat = 6
        let leftPadding: CGFloat = position.startFret > 0 ? 24 : 15
        let rightPadding: CGFloat = 15

        Canvas { context, size in
            let originX = leftPadding
            let originY = topMargin

            // Draw nut or fret position indicator
            if position.startFret == 0 {
                let nutRect = CGRect(x: originX - 1, y: originY - 3, width: gridWidth + 2, height: 3)
                context.fill(Path(nutRect), with: .color(.primary))
            } else {
                let fretText = Text("\(position.startFret)fr")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                context.draw(fretText, at: CGPoint(x: originX - 12, y: originY + fretSpacing / 2))
            }

            // Draw fret lines (horizontal)
            for i in 0...position.fretCount {
                let y = originY + CGFloat(i) * fretSpacing
                var path = Path()
                path.move(to: CGPoint(x: originX, y: y))
                path.addLine(to: CGPoint(x: originX + gridWidth, y: y))
                context.stroke(path, with: .color(.secondary.opacity(0.5)), lineWidth: 1)
            }

            // Draw string lines (vertical)
            for i in 0..<numStrings {
                let x = originX + CGFloat(i) * stringSpacing
                var path = Path()
                path.move(to: CGPoint(x: x, y: originY))
                path.addLine(to: CGPoint(x: x, y: originY + gridHeight))
                context.stroke(path, with: .color(.secondary.opacity(0.6)), lineWidth: 1)
            }

            let effectiveBaseFret = max(position.startFret, 1)

            // Draw scale tone and root dots
            for stringIndex in 0..<numStrings {
                let x = originX + CGFloat(stringIndex) * stringSpacing
                let stringFrets = position.frets[stringIndex]
                let stringRoots = position.roots[stringIndex]

                for fret in stringFrets {
                    let isRoot = stringRoots.contains(fret)
                    let radius = isRoot ? rootRadius : scaleRadius
                    let color: Color = isRoot ? .purple : .primary

                    if fret == 0 && position.startFret == 0 {
                        // Open string: filled dot above nut
                        let markerY = originY - 8
                        let dot = Path(ellipseIn: CGRect(
                            x: x - radius, y: markerY - radius,
                            width: radius * 2, height: radius * 2
                        ))
                        context.fill(dot, with: .color(color))
                    } else {
                        let relativeFret = fret - effectiveBaseFret + 1
                        let dotY = originY + (CGFloat(relativeFret) - 0.5) * fretSpacing
                        let dot = Path(ellipseIn: CGRect(
                            x: x - radius, y: dotY - radius,
                            width: radius * 2, height: radius * 2
                        ))
                        context.fill(dot, with: .color(color))
                    }
                }
            }
        }
        .frame(width: leftPadding + gridWidth + rightPadding, height: topMargin + gridHeight + 4)
    }
}
