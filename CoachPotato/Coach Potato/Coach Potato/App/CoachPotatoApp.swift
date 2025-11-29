import SwiftUI
import SwiftData

@main
struct CoachPotatoApp: App {
    @StateObject private var container = DIContainer()
    private let modelContainer: ModelContainer

    init() {
        modelContainer = SwiftDataStack.shared
    }

    var body: some Scene {
        WindowGroup {
            AppNavigation()
                .environmentObject(container)
                .modelContainer(modelContainer)
        }
    }
}
