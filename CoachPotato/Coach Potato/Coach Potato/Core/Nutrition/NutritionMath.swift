import Foundation

/// Namespace for simple nutrition-related calculations.
enum NutritionMath {
    /// Calculates total calories for given macro grams using standard multipliers.
    static func calories(fromProtein protein: Double, carbs: Double, fat: Double) -> Double {
        let proteinCalories = protein * 4.0
        let carbCalories = carbs * 4.0
        let fatCalories = fat * 9.0
        return proteinCalories + carbCalories + fatCalories
    }

    /// Returns macro distribution as percentages of total calories.
    /// If total calories are zero, returns 0 for each percentage.
    static func macroPercentages(protein: Double, carbs: Double, fat: Double) -> MacroPercentages {
        let totalCalories = calories(fromProtein: protein, carbs: carbs, fat: fat)
        guard totalCalories > 0 else {
            return MacroPercentages(protein: 0, carbs: 0, fat: 0)
        }

        let proteinPercent = (protein * 4.0) / totalCalories
        let carbPercent = (carbs * 4.0) / totalCalories
        let fatPercent = (fat * 9.0) / totalCalories
        return MacroPercentages(protein: proteinPercent, carbs: carbPercent, fat: fatPercent)
    }
}

struct MacroPercentages {
    let protein: Double
    let carbs: Double
    let fat: Double
}
