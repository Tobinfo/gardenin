import SwiftUI

@main
struct GardenSnapApp: App {
    @StateObject private var store = PlantStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
