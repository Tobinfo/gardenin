import SwiftUI

struct PlantDetailView: View {
    @EnvironmentObject private var store: PlantStore
    @State private var showingHealthNote = false

    let plantID: PlantInstance.ID

    private var plant: PlantInstance? {
        store.plants.first(where: { $0.id == plantID })
    }

    var body: some View {
        Group {
            if let plant {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(plant.species.commonName)
                                .font(.title3.weight(.semibold))

                            if let scientificName = plant.species.scientificName {
                                Text(scientificName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(plant.species.careNotes)
                                .font(.body)
                        }
                        .padding(.vertical, 6)
                    }

                    Section("Next actions") {
                        ForEach(store.recommendations(for: plant)) { recommendation in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Label(recommendation.title, systemImage: icon(for: recommendation.action))
                                        .font(.headline)
                                    Spacer()
                                    Text(recommendation.status.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(statusColor(recommendation.status))
                                }

                                Text(recommendation.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section("Log care") {
                        HStack {
                            careButton("Watered", icon: "drop.fill", action: .water)
                            careButton("Fertilized", icon: "leaf.fill", action: .fertilize)
                            careButton("Pruned", icon: "scissors", action: .prune)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            showingHealthNote = true
                        } label: {
                            Label("Add health note", systemImage: "exclamationmark.bubble")
                        }
                    }

                    if !plant.healthNotes.isEmpty {
                        Section("Health notes") {
                            ForEach(plant.healthNotes) { note in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(note.title)
                                        .font(.headline)
                                    Text(note.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    if !plant.careLogs.isEmpty {
                        Section("Care history") {
                            ForEach(plant.careLogs) { log in
                                LabeledContent(log.action.label) {
                                    Text(log.date, style: .date)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(plant.nickname)
                .sheet(isPresented: $showingHealthNote) {
                    HealthNoteView(plantID: plant.id)
                }
            } else {
                ContentUnavailableView("Plant not found", systemImage: "leaf")
            }
        }
    }

    private func careButton(_ title: String, icon: String, action: CareActionKind) -> some View {
        Button {
            store.logCare(for: plantID, action: action)
        } label: {
            Label(title, systemImage: icon)
                .labelStyle(.iconOnly)
                .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(title)
    }

    private func icon(for action: CareActionKind) -> String {
        switch action {
        case .water: "drop"
        case .fertilize: "leaf"
        case .prune: "scissors"
        case .inspect: "stethoscope"
        }
    }

    private func statusColor(_ status: CareStatus) -> Color {
        switch status {
        case .dueNow: .red
        case .dueSoon: .orange
        case .scheduled: .green
        case .paused: .secondary
        }
    }
}

private struct HealthNoteView: View {
    @EnvironmentObject private var store: PlantStore
    @Environment(\.dismiss) private var dismiss

    let plantID: PlantInstance.ID

    @State private var title = ""
    @State private var detail = ""
    @State private var severity: HealthSeverity = .watch

    var body: some View {
        NavigationStack {
            Form {
                TextField("Issue", text: $title)
                TextField("Notes", text: $detail, axis: .vertical)

                Picker("Severity", selection: $severity) {
                    Text("None").tag(HealthSeverity.none)
                    Text("Watch").tag(HealthSeverity.watch)
                    Text("Action").tag(HealthSeverity.action)
                }
            }
            .navigationTitle("Health Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addHealthNote(
                            for: plantID,
                            title: title.isEmpty ? "Garden note" : title,
                            detail: detail,
                            severity: severity
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
