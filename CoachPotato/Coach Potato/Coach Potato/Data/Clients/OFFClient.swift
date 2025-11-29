import Foundation

protocol OFFClient {
    func searchFoods(matching query: String, page: Int) async throws -> [FoodSearchResult]
}

struct StubOFFClient: OFFClient {
    func searchFoods(matching query: String, page: Int) async throws -> [FoodSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return [
            FoodSearchResult(
                id: "off_stub_\(page)",
                name: "Sample OFF Food",
                brand: "Open Food Facts",
                caloriesPer100g: 120,
                proteinPer100g: 4,
                carbsPer100g: 22,
                fatPer100g: 2,
                source: .off
            )
        ]
    }
}
