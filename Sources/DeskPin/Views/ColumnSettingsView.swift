import SwiftUI

struct ColumnSettingsView: View {
    @State var config: ColumnConfig
    @ObservedObject var store: BoardStore
    @Binding var isPresented: Bool

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Column Settings")
                .font(.system(size: 14, weight: .bold))

            // Name
            HStack {
                Text("Name:")
                    .font(.system(size: 12))
                    .frame(width: 50, alignment: .trailing)
                TextField("Column name", text: $config.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            // Type
            HStack {
                Text("Type:")
                    .font(.system(size: 12))
                    .frame(width: 50, alignment: .trailing)
                Picker("", selection: $config.type) {
                    Text("TODO").tag(ColumnType.todo)
                    Text("DONE").tag(ColumnType.done)
                    Text("NOTE").tag(ColumnType.note)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // Color
            VStack(alignment: .leading, spacing: 6) {
                Text("Color:")
                    .font(.system(size: 12))

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 6), count: 5), spacing: 6) {
                    ForEach(ColorOption.all) { opt in
                        Circle()
                            .fill(Color(hex: opt.hex))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: config.colorHex == opt.hex ? 2.5 : 0)
                            )
                            .shadow(color: config.colorHex == opt.hex ? Color(hex: opt.hex).opacity(0.5) : .clear, radius: 4)
                            .onTapGesture {
                                config.colorHex = opt.hex
                            }
                    }
                }
            }

            Divider()

            // Actions
            HStack {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Column", systemImage: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Cancel") {
                    isPresented = false
                }
                .font(.system(size: 11))
                .controlSize(.small)

                Button("Save") {
                    store.updateColumn(config)
                    isPresented = false
                }
                .font(.system(size: 11, weight: .medium))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(20)
        .frame(width: 280)
        .alert("Delete '\(config.name)'?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                store.removeColumn(config.id)
                isPresented = false
                // Notify AppDelegate to close the orphaned window
                NotificationCenter.default.post(name: .columnDeleted, object: config.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the column and all its data.")
        }
    }
}
