import Foundation

#if canImport(Testing)
import Testing
@testable import Coach_Potato

struct FoodSearchTests {

    // MARK: - Repository tests

    @Test func repository_returns_empty_for_blank_queries() async throws {
        let client = StaticSearchClient(result: .success([]))
        let repo = RemoteFoodSearchRepository(fdcClient: client, offClient: client)

        let results = try await repo.search(query: "   ", page: 1)

        #expect(results.isEmpty)
        #expect(await client.callCount == 0)
    }

    @Test func repository_prefers_fdc_success() async throws {
        let expected = FoodSearchResult(
            id: "fdc1",
            name: "Apple",
            brand: "FDC",
            caloriesPer100g: 52,
            proteinPer100g: 0.3,
            carbsPer100g: 14,
            fatPer100g: 0.2,
            source: .fdc
        )

        let fdc = StaticSearchClient(result: .success([expected]))
        let off = StaticSearchClient(result: .success([]))
        let repo = RemoteFoodSearchRepository(fdcClient: fdc, offClient: off)

        let results = try await repo.search(query: "apple", page: 1)

        #expect(results == [expected])
        #expect(await fdc.callCount == 1)
        #expect(await off.callCount == 0)
    }

    @Test func repository_falls_back_to_off_on_failure() async throws {
        enum SampleError: Error { case failure }

        let offResult = FoodSearchResult(
            id: "off1",
            name: "Banana",
            brand: "OFF",
            caloriesPer100g: 89,
            proteinPer100g: 1.1,
            carbsPer100g: 23,
            fatPer100g: 0.3,
            source: .off
        )

        let fdc = StaticSearchClient(result: .failure(SampleError.failure))
        let off = StaticSearchClient(result: .success([offResult]))
        let repo = RemoteFoodSearchRepository(fdcClient: fdc, offClient: off)

        let results = try await repo.search(query: "banana", page: 2)

        #expect(results == [offResult])
        #expect(await fdc.callCount == 1)
        #expect(await off.callCount == 1)
    }

    // MARK: - View model tests

    @MainActor
    @Test func view_model_clears_state_for_empty_query() async throws {
        let repo = FakeFoodSearchRepository()
        let viewModel = FoodSearchViewModel(repository: repo)

        viewModel.query = "   "
        await viewModel.performSearch()

        #expect(viewModel.results.isEmpty)
        #expect(viewModel.canLoadMore == false)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func view_model_perform_search_sets_results_and_canLoadMore() async throws {
        let repo = FakeFoodSearchRepository()
        await repo.setResponse([FoodSearchResult(
            id: "1",
            name: "Orange",
            brand: nil,
            caloriesPer100g: 47,
            proteinPer100g: 0.9,
            carbsPer100g: 12,
            fatPer100g: 0.1,
            source: .fdc
        )], forPage: 1)

        let viewModel = FoodSearchViewModel(repository: repo)
        viewModel.query = "orange"
        await viewModel.performSearch()

        #expect(viewModel.results.count == 1)
        #expect(viewModel.canLoadMore == true)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func view_model_load_more_appends_and_disables_when_empty() async throws {
        let repo = FakeFoodSearchRepository()
        await repo.setResponse([FoodSearchResult(
            id: "1",
            name: "Peach",
            brand: nil,
            caloriesPer100g: 39,
            proteinPer100g: 0.9,
            carbsPer100g: 10,
            fatPer100g: 0.3,
            source: .fdc
        )], forPage: 1)

        await repo.setResponse([], forPage: 2)

        let viewModel = FoodSearchViewModel(repository: repo)
        viewModel.query = "peach"
        await viewModel.performSearch()
        await viewModel.loadMore()

        #expect(viewModel.results.count == 1)
        #expect(viewModel.canLoadMore == false)
    }
}

// MARK: - Test doubles

actor StaticSearchClient: FDCClient, OFFClient {
    private let result: Result<[FoodSearchResult], Error>
    private(set) var callCount: Int = 0

    init(result: Result<[FoodSearchResult], Error>) {
        self.result = result
    }

    func searchFoods(matching query: String, page: Int) async throws -> [FoodSearchResult] {
        callCount += 1
        switch result {
        case .success(let values):
            return values
        case .failure(let error):
            throw error
        }
    }
}

actor FakeFoodSearchRepository: FoodSearchRepository {
    enum StubError: Error { case stubbed }

    private var responses: [Int: [FoodSearchResult]] = [:]
    var shouldThrow = false

    func setResponse(_ results: [FoodSearchResult], forPage page: Int) {
        responses[page] = results
    }

    func search(query: String, page: Int) async throws -> [FoodSearchResult] {
        if shouldThrow { throw StubError.stubbed }
        return responses[page] ?? []
    }
}
#endif
