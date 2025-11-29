import Foundation

/// Macro targets expressed in calories and grams.
struct MacroPlan {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    /// Initializes a plan from calorie target and macro ratios that must sum to 1.0.
    init(calories: Double, proteinRatio: Double, carbRatio: Double, fatRatio: Double) {
        let ratioSum = proteinRatio + carbRatio + fatRatio
        precondition(abs(ratioSum - 1.0) < 0.0001, "Macro ratios must sum to 1.0")

        let proteinCalories = calories * proteinRatio
        let carbCalories = calories * carbRatio
        let fatCalories = calories * fatRatio

        self.calories = calories
        self.protein = proteinCalories / 4.0
        self.carbs = carbCalories / 4.0
        self.fat = fatCalories / 9.0
    }
}
