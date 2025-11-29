import Foundation
import Testing
@testable import Coach_Potato

struct CoreLogicTests {
    @Test func calories_computation_matches_expected() {
        let calories = NutritionMath.calories(fromProtein: 25, carbs: 50, fat: 10)
        #expect(abs(calories - 390) < 0.0001)
    }

    @Test func macro_percentages_handles_zero_safely() {
        let percentages = NutritionMath.macroPercentages(protein: 0, carbs: 0, fat: 0)
        #expect(percentages.protein == 0)
        #expect(percentages.carbs == 0)
        #expect(percentages.fat == 0)
    }

    @Test func mifflin_st_jeor_male_example() {
        let bmr = MacroCalculatorMSJ.bmrMale(weightKg: 70, heightCm: 175, ageYears: 30)
        #expect(abs(bmr - 1648.75) < 0.5)
    }

    @Test func mifflin_st_jeor_female_example() {
        let bmr = MacroCalculatorMSJ.bmrFemale(weightKg: 60, heightCm: 165, ageYears: 28)
        #expect(abs(bmr - 1330.25) < 0.5)
    }

    @Test func macro_plan_ratios_generate_expected_grams() {
        let plan = MacroPlan(calories: 2100, proteinRatio: 0.3, carbRatio: 0.4, fatRatio: 0.3)
        let computedCalories = NutritionMath.calories(fromProtein: plan.protein, carbs: plan.carbs, fat: plan.fat)
        #expect(abs(computedCalories - 2100) < 0.5)
    }

    @Test func mocked_http_client_decodes_payload() async throws {
        struct Payload: Codable, Equatable, Sendable { let message: String }

        final class MockHTTPClient: HTTPClient {
            var lastRequest: HTTPRequest?
            let payload: Payload

            init(payload: Payload) {
                self.payload = payload
            }

            func send<T: Decodable & Sendable>(_ request: HTTPRequest, decodeTo type: T.Type) async throws -> T {
                lastRequest = request
                let data = try JSONEncoder().encode(payload)
                return try JSONDecoder().decode(T.self, from: data)
            }
        }

        let expected = Payload(message: "hello")
        let client = MockHTTPClient(payload: expected)
        let request = HTTPRequest(url: URL(string: "https://example.com/mock")!)

        let result: Payload = try await client.send(request, decodeTo: Payload.self)

        #expect(result == expected)
        #expect(client.lastRequest?.url.absoluteString == "https://example.com/mock")
    }
}
