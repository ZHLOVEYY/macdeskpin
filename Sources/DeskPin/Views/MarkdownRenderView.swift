import SwiftUI

struct MarkdownRenderView: View {
    let content: String
    var onToggleCheckbox: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            let lines = content.components(separatedBy: "\n")
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    Spacer().frame(height: 4)
                } else if line.hasPrefix("# ") {
                    Text(line.dropFirst(2))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                } else if line.hasPrefix("## ") {
                    Text(line.dropFirst(3))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                } else if line.hasPrefix("### ") {
                    Text(line.dropFirst(4))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                } else if line.contains("- [x]") {
                    checkboxLine(line: line, checked: true, index: index)
                } else if line.contains("- [ ]") {
                    checkboxLine(line: line, checked: false, index: index)
                } else if line.hasPrefix("- ") {
                    HStack(alignment: .top, spacing: 4) {
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        renderInlineMarkdown(String(line.dropFirst(2)))
                    }
                } else if line.hasPrefix("> ") {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 3)
                        renderInlineMarkdown(String(line.dropFirst(2)))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 1)
                } else {
                    renderInlineMarkdown(line)
                }
            }
        }
    }

    private func checkboxLine(line: String, checked: Bool, index: Int) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Button(action: {
                onToggleCheckbox?(index)
            }) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13))
                    .foregroundStyle(checked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            let text = line
                .replacingOccurrences(of: "- [x] ", with: "")
                .replacingOccurrences(of: "- [ ] ", with: "")
            Text(text)
                .font(.system(size: 12))
                .strikethrough(checked, color: .secondary)
                .foregroundStyle(checked ? .secondary : .primary)
        }
    }

    @ViewBuilder
    private func renderInlineMarkdown(_ text: String) -> some View {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
                .font(.system(size: 12))
        } else {
            Text(text)
                .font(.system(size: 12))
        }
    }
}
