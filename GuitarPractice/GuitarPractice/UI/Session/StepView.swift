import SwiftUI

struct StepView: View {
    let name: String
    let instructions: String
    let notes: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.largeSpacing) {
            Text(name)
                .font(.title2)
                .fontWeight(.semibold)

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.mediumSpacing) {
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
}
