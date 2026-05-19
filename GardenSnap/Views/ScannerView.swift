import SwiftUI
import UIKit

struct ScannerView: View {
    @EnvironmentObject private var store: PlantStore
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var candidates: [PlantIdentificationCandidate] = []
    @State private var selectedCandidate: PlantIdentificationCandidate?
    @State private var isIdentifying = false
    @State private var errorMessage: String?

    private let identifier: PlantIdentificationService = DemoPlantIdentificationService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                scanSurface

                if isIdentifying {
                    ProgressView("Identifying plant")
                        .controlSize(.large)
                } else if candidates.isEmpty {
                    emptyState
                } else {
                    candidateList
                }
            }
            .padding()
            .navigationTitle("Fast Scan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                    }
                    .accessibilityLabel("Open camera")
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraCaptureView(image: $capturedImage)
                    .ignoresSafeArea()
            }
            .sheet(item: $selectedCandidate) { candidate in
                AddPlantReviewView(
                    candidate: candidate,
                    suggestedName: store.suggestedName(for: candidate.profile)
                )
            }
            .onChange(of: capturedImage) { _, newImage in
                guard let newImage else {
                    return
                }
                identify(newImage)
            }
            .alert("Scan failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var scanSurface: some View {
        Button {
            showingCamera = true
        } label: {
            VStack(spacing: 12) {
                if let capturedImage {
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                            .clipped()

                        if let candidate = candidates.first, let box = candidate.observationBox {
                            GeometryReader { proxy in
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.yellow, lineWidth: 3)
                                        .frame(
                                            width: proxy.size.width * box.width,
                                            height: proxy.size.height * box.height
                                        )
                                        .offset(
                                            x: proxy.size.width * box.x,
                                            y: proxy.size.height * box.y
                                        )

                                    Text(candidate.profile.commonName)
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(.yellow)
                                        .foregroundStyle(.black)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .offset(
                                            x: proxy.size.width * box.x,
                                            y: max(0, proxy.size.height * box.y - 30)
                                        )
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.green.opacity(0.12))
                            .frame(height: 280)

                        VStack(spacing: 10) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 42, weight: .semibold))
                            Text("Tap to scan")
                                .font(.headline)
                        }
                        .foregroundStyle(.green)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("Scan a plant to get a likely ID, suggested name, care timing, and health checks.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingCamera = true
            } label: {
                Label("Start scan", systemImage: "camera")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
    }

    private var candidateList: some View {
        List(candidates) { candidate in
            Button {
                selectedCandidate = candidate
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.profile.commonName)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if let scientificName = candidate.profile.scientificName {
                            Text(scientificName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let issue = candidate.observedIssues.first {
                            Label(issue.title, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    Spacer()

                    Text(candidate.confidence, format: .percent.precision(.fractionLength(0)))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
    }

    private func identify(_ image: UIImage) {
        isIdentifying = true
        candidates = []

        Task {
            do {
                let found = try await identifier.identify(image: image)
                await MainActor.run {
                    candidates = found
                    isIdentifying = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "GardenSnap could not identify a plant in this photo."
                    isIdentifying = false
                }
            }
        }
    }
}

struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        controller.allowsEditing = false
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let image: Binding<UIImage?>
        private let dismiss: DismissAction

        init(image: Binding<UIImage?>, dismiss: DismissAction) {
            self.image = image
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            image.wrappedValue = info[.originalImage] as? UIImage
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

#Preview {
    ScannerView()
        .environmentObject(PlantStore())
}
