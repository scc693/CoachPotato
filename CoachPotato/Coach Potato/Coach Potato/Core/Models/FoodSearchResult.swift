import Foundation

struct FoodSearchResult: Codable, Equatable {
    let id: String
    let name: String
    let brand: String?
    let caloriesPer100g: Double?
    let proteinPer100g: Double?
    let carbsPer100g: Double?
    let fatPer100g: Double?
    let source: FoodSource
}
