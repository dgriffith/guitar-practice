import SwiftUI

struct ChordDiagramView: View {
    let chordName: String
    let isActive: Bool

    private let numStrings = 6
    private let numFrets = 4

    var body: some View {
        VStack(spacing: 4) {
            Text(chordName)
                .font(.headline)
                .fontWeight(isActive ? .bold : .medium)
                .foregroundStyle(isActive ? .primary : .secondary)

            if let fingering = ChordLibrary.fingering(for: chordName) {
                diagramView(fingering: fingering)
            } else {
                // Unknown chord — just show the name prominently
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 80, height: 90)
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
    private func diagramView(fingering: ChordFingering) -> some View {
        let stringSpacing: CGFloat = 14
        let fretSpacing: CGFloat = 18
        let gridWidth = CGFloat(numStrings - 1) * stringSpacing
        let gridHeight = CGFloat(numFrets) * fretSpacing
        let topMargin: CGFloat = 14 // space for open/mute markers
        let dotRadius: CGFloat = 5

        Canvas { context, size in
            let originX = (size.width - gridWidth) / 2
            let originY = topMargin

            // Draw nut or fret position indicator
            if fingering.baseFret == 1 {
                // Thick nut line at top
                let nutRect = CGRect(x: originX - 1, y: originY - 3, width: gridWidth + 2, height: 3)
                context.fill(Path(nutRect), with: .color(.primary))
            } else {
                // Fret number label
                let fretText = Text("\(fingering.baseFret)fr")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                context.draw(fretText, at: CGPoint(x: originX - 12, y: originY + fretSpacing / 2))
            }

            // Draw fret lines (horizontal)
            for i in 0...numFrets {
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

            // Draw barre indicators
            for barre in fingering.barres {
                let barreY = originY + (CGFloat(barre) - 0.5) * fretSpacing
                // Find the string range for the barre
                let fretValue = barre + fingering.baseFret - 1
                var firstString = -1
                var lastString = -1
                for s in 0..<numStrings {
                    if fingering.frets[s] == fretValue {
                        if firstString == -1 { firstString = s }
                        lastString = s
                    }
                }
                if firstString >= 0 && lastString > firstString {
                    let x1 = originX + CGFloat(firstString) * stringSpacing
                    let x2 = originX + CGFloat(lastString) * stringSpacing
                    let barreRect = RoundedRectangle(cornerRadius: dotRadius)
                        .path(in: CGRect(
                            x: x1 - dotRadius,
                            y: barreY - dotRadius,
                            width: x2 - x1 + dotRadius * 2,
                            height: dotRadius * 2
                        ))
                    context.fill(barreRect, with: .color(.primary))
                }
            }

            // Draw finger dots, open strings, and muted strings
            for stringIndex in 0..<numStrings {
                let x = originX + CGFloat(stringIndex) * stringSpacing
                let fret = fingering.frets[stringIndex]

                if fret == -1 {
                    // Muted string: X above the nut
                    let xSize: CGFloat = 4
                    let markerY = originY - 8
                    var path = Path()
                    path.move(to: CGPoint(x: x - xSize, y: markerY - xSize))
                    path.addLine(to: CGPoint(x: x + xSize, y: markerY + xSize))
                    path.move(to: CGPoint(x: x + xSize, y: markerY - xSize))
                    path.addLine(to: CGPoint(x: x - xSize, y: markerY + xSize))
                    context.stroke(path, with: .color(.secondary), lineWidth: 1.5)
                } else if fret == 0 {
                    // Open string: O above the nut
                    let markerY = originY - 8
                    let circle = Path(ellipseIn: CGRect(
                        x: x - 4, y: markerY - 4, width: 8, height: 8
                    ))
                    context.stroke(circle, with: .color(.secondary), lineWidth: 1.5)
                } else {
                    // Fretted note: filled dot
                    let relativeFret = fret - fingering.baseFret + 1
                    let dotY = originY + (CGFloat(relativeFret) - 0.5) * fretSpacing
                    let dot = Path(ellipseIn: CGRect(
                        x: x - dotRadius, y: dotY - dotRadius,
                        width: dotRadius * 2, height: dotRadius * 2
                    ))
                    context.fill(dot, with: .color(.primary))
                }
            }
        }
        .frame(width: gridWidth + 30, height: topMargin + gridHeight + 4)
    }
}
