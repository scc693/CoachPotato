import Foundation

struct FoodDetail: Codable, Equatable {
    let summary: FoodSearchResult
    let description: String?
    let servingSizeGrams: Double?
    let servingsPerContainer: Double?

    init(summary: FoodSearchResult, description: String? = nil, servingSizeGrams: Double? = nil, servingsPerContainer: Double? = nil) {
        self.summary = summary
        self.description = description
        self.servingSizeGrams = servingSizeGrams
        self.servingsPerContainer = servingsPerContainer
    }
}
