import SwiftUI

struct StepView: View {
    let name: String
    let instructions: String
    let notes: String?
    let chords: [String]?
    let currentChordIndex: Int
    let images: [String]?
    let scales: [String]?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.largeSpacing) {
            Text(name)
                .font(.title2)
                .fontWeight(.semibold)

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.mediumSpacing) {
                    // Chord progression display
                    if let chords, !chords.isEmpty {
                        chordProgressionView(chords: chords)
                    }

                    // Scale diagram display
                    if let scales, !scales.isEmpty {
                        scaleDisplayView(scales: scales)
                    }

                    // Image display
                    if let images, !images.isEmpty {
                        imageGalleryView(images: images)
                    }

                    Text(instructions)
                        .font(.body)
                        .lineSpacing(4)
                        .textSelection(.enabled)

                    if let notes {
                        HStack(alignment: .top, spacing: Theme.spacing) {
                            Image(systemName: "lightbulb")
                                .foregroundStyle(.yellow)
                            Text(notes)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(Theme.mediumSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                }
            }
        }
    }

    // MARK: - Chord Progression

    @ViewBuilder
    private func chordProgressionView(chords: [String]) -> some View {
        VStack(spacing: Theme.mediumSpacing) {
            // Chord diagrams in a horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.largeSpacing) {
                    ForEach(Array(chords.enumerated()), id: \.offset) { index, chord in
                        ChordDiagramView(
                            chordName: chord,
                            isActive: index == currentChordIndex
                        )
                        .scaleEffect(index == currentChordIndex ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 0.2), value: currentChordIndex)
                    }
                }
                .padding(.horizontal, Theme.mediumSpacing)
                .padding(.vertical, Theme.spacing)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacing)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: Theme.largeCornerRadius))
    }

    // MARK: - Scale Display

    @ViewBuilder
    private func scaleDisplayView(scales: [String]) -> some View {
        VStack(spacing: Theme.mediumSpacing) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.largeSpacing) {
                    ForEach(scales, id: \.self) { scale in
                        ScaleDiagramView(scaleName: scale, isActive: true)
                    }
                }
                .padding(.horizontal, Theme.mediumSpacing)
                .padding(.vertical, Theme.spacing)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacing)
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: Theme.largeCornerRadius))
    }

    // MARK: - Image Gallery

    @ViewBuilder
    private func imageGalleryView(images: [String]) -> some View {
        VStack(spacing: Theme.spacing) {
            ForEach(images, id: \.self) { imageName in
                stepImage(named: imageName)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func stepImage(named imageName: String) -> some View {
        if let nsImage = loadImage(named: imageName) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        } else {
            Label(imageName, systemImage: "photo")
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(Theme.mediumSpacing)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
    }

    private func loadImage(named imageName: String) -> NSImage? {
        if let url = Bundle.main.url(forResource: imageName, withExtension: nil, subdirectory: "Images") {
            return NSImage(contentsOf: url)
        }
        if let url = Bundle.main.url(forResource: imageName, withExtension: nil) {
            return NSImage(contentsOf: url)
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let userImageURL = appSupport
            .appendingPathComponent("GuitarPractice/Images", isDirectory: true)
            .appendingPathComponent(imageName)
        if FileManager.default.fileExists(atPath: userImageURL.path) {
            return NSImage(contentsOf: userImageURL)
        }
        if FileManager.default.fileExists(atPath: imageName) {
            return NSImage(contentsOfFile: imageName)
        }
        return nil
    }
}
