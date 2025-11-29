import Foundation

protocol FDCClient {
    func searchFoods(matching query: String, page: Int) async throws -> [FoodSearchResult]
}

struct StubFDCClient: FDCClient {
    func searchFoods(matching query: String, page: Int) async throws -> [FoodSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return [
            FoodSearchResult(
                id: "fdc_stub_\(page)",
                name: "Sample FDC Food",
                brand: "FDC",
                caloriesPer100g: 150,
                proteinPer100g: 8,
                carbsPer100g: 18,
                fatPer100g: 5,
                source: .fdc
            )
        ]
    }
}
