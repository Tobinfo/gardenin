import SwiftUI

struct GardenView: View {
    @EnvironmentObject private var store: PlantStore
    @State private var showingQuickAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if store.plants.isEmpty {
                    ContentUnavailableView(
                        "No plants yet",
                        systemImage: "leaf",
                        description: Text("Scan plants as you walk the garden and they will show up here.")
                    )
                } else {
                    List(store.plants) { plant in
                        NavigationLink(value: plant.id) {
                            PlantRow(plant: plant, recommendations: store.recommendations(for: plant))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Garden")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingQuickAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Quick add plant")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await store.refreshWeather()
                        }
                    } label: {
                        Image(systemName: store.isRefreshingWeather ? "arrow.triangle.2.circlepath" : "cloud.sun")
                    }
                    .accessibilityLabel("Refresh weather")
                }
            }
            .navigationDestination(for: PlantInstance.ID.self) { plantID in
                PlantDetailView(plantID: plantID)
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddPlantView()
            }
        }
    }
}

private struct QuickAddPlantView: View {
    @EnvironmentObject private var store: PlantStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProfile = PlantSamples.knownProfiles[0]
    @State private var nickname = ""
    @State private var setting: GrowthSetting = .gardenBed
    @State private var sunExposure: SunExposure = .partSun
    @State private var locationNote = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant") {
                    Picker("Species", selection: $selectedProfile) {
                        ForEach(PlantSamples.knownProfiles) { profile in
                            Text(profile.commonName).tag(profile)
                        }
                    }

                    TextField("Name", text: $nickname)
                        .textInputAutocapitalization(.words)
                }

                Section("Placement") {
                    Picker("Setting", selection: $setting) {
                        ForEach(GrowthSetting.allCases) { setting in
                            Text(setting.label).tag(setting)
                        }
                    }

                    Picker("Sun", selection: $sunExposure) {
                        ForEach(SunExposure.allCases) { exposure in
                            Text(exposure.label).tag(exposure)
                        }
                    }

                    TextField("Garden spot", text: $locationNote)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Care profile") {
                    Text(selectedProfile.careNotes)
                    LabeledContent("Watering", value: "\(selectedProfile.minimumWateringDays)-\(selectedProfile.maximumWateringDays) days")
                    LabeledContent("Fertilizer", value: "Every \(selectedProfile.fertilizeEveryDays) days")
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: refreshSuggestedName)
            .onChange(of: selectedProfile) { _, _ in
                refreshSuggestedName()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
        }
    }

    private func refreshSuggestedName() {
        nickname = store.suggestedName(for: selectedProfile)
    }

    private func save() {
        let candidate = PlantIdentificationCandidate(
            profile: selectedProfile,
            confidence: 1,
            observedIssues: [],
            observationBox: nil,
            metadata: PlantIdentificationMetadata(
                providerName: "Manual entry",
                providerPlantID: nil,
                source: "quick-add"
            )
        )

        store.addPlant(
            from: candidate,
            nickname: nickname.isEmpty ? store.suggestedName(for: selectedProfile) : nickname,
            setting: setting,
            sunExposure: sunExposure,
            locationNote: locationNote
        )
        dismiss()
    }
}

private struct PlantRow: View {
    let plant: PlantInstance
    let recommendations: [CareRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plant.nickname)
                        .font(.headline)
                    Text(plant.species.commonName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let topRecommendation = recommendations.first {
                    Text(topRecommendation.status.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(topRecommendation.status).opacity(0.16))
                        .foregroundStyle(statusColor(topRecommendation.status))
                        .clipShape(Capsule())
                }
            }

            if let topRecommendation = recommendations.first {
                Label(topRecommendation.title, systemImage: icon(for: topRecommendation.action))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !plant.locationNote.isEmpty {
                Text(plant.locationNote)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
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

#Preview {
    GardenView()
        .environmentObject(PlantStore())
}
