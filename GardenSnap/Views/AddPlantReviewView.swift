import SwiftUI

struct AddPlantReviewView: View {
    @EnvironmentObject private var store: PlantStore
    @Environment(\.dismiss) private var dismiss

    let candidate: PlantIdentificationCandidate
    let suggestedName: String

    @State private var nickname: String
    @State private var setting: GrowthSetting = .gardenBed
    @State private var sunExposure: SunExposure = .partSun
    @State private var locationNote = ""

    init(candidate: PlantIdentificationCandidate, suggestedName: String) {
        self.candidate = candidate
        self.suggestedName = suggestedName
        _nickname = State(initialValue: suggestedName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plant") {
                    LabeledContent("Match", value: candidate.profile.commonName)
                    LabeledContent("Confidence", value: candidate.confidence.formatted(.percent.precision(.fractionLength(0))))

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

                if !candidate.observedIssues.isEmpty {
                    Section("Health watch") {
                        ForEach(candidate.observedIssues) { issue in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(issue.title)
                                    .font(.headline)
                                Text(issue.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Care profile") {
                    Text(candidate.profile.careNotes)
                    LabeledContent("Watering", value: "\(candidate.profile.minimumWateringDays)-\(candidate.profile.maximumWateringDays) days")
                    LabeledContent("Fertilizer", value: "Every \(candidate.profile.fertilizeEveryDays) days")
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addPlant(
                            from: candidate,
                            nickname: nickname.isEmpty ? suggestedName : nickname,
                            setting: setting,
                            sunExposure: sunExposure,
                            locationNote: locationNote
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
