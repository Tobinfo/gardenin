import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: PlantStore

    var body: some View {
        TabView {
            ScannerView()
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }

            GardenView()
                .tabItem {
                    Label("Garden", systemImage: "leaf")
                }
        }
        .task {
            await store.refreshWeather()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(PlantStore())
}
