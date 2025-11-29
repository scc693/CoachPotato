import Foundation

/// Mifflin-St Jeor based calculations for basal and total energy expenditure.
enum MacroCalculatorMSJ {
    /// Basal Metabolic Rate for males.
    static func bmrMale(weightKg: Double, heightCm: Double, ageYears: Int) -> Double {
        (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * Double(ageYears)) + 5.0
    }

    /// Basal Metabolic Rate for females.
    static func bmrFemale(weightKg: Double, heightCm: Double, ageYears: Int) -> Double {
        (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * Double(ageYears)) - 161.0
    }

    /// Total Daily Energy Expenditure from a BMR and an activity multiplier.
    static func tdee(fromBMR bmr: Double, activityMultiplier: Double) -> Double {
        bmr * activityMultiplier
    }
}
