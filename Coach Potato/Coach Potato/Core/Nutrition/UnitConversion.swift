import Foundation

enum UnitConversion {
    static func gramsToKilograms(_ grams: Double) -> Double {
        grams / 1000.0
    }

    static func kilogramsToGrams(_ kilograms: Double) -> Double {
        kilograms * 1000.0
    }

    static func servings(forGrams grams: Double, gramsPerServing: Double) -> Double {
        guard gramsPerServing > 0 else { return 0 }
        return grams / gramsPerServing
    }

    static func grams(forServings servings: Double, gramsPerServing: Double) -> Double {
        servings * gramsPerServing
    }
}
