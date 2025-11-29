import Foundation
import SwiftData

enum SwiftDataStack {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: PlaceholderEntity.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()
}

@Model
final class PlaceholderEntity {
    var id: UUID

    init(id: UUID = UUID()) {
        self.id = id
    }
}
