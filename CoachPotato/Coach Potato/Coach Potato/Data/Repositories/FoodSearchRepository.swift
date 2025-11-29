import Foundation

protocol FoodSearchRepository {
    func search(query: String, page: Int) async throws -> [FoodSearchResult]
}

/// Remote-backed implementation that prefers FDC and falls back to OFF on failure.
struct RemoteFoodSearchRepository: FoodSearchRepository {
    private let fdcClient: FDCClient
    private let offClient: OFFClient

    init(fdcClient: FDCClient, offClient: OFFClient) {
        self.fdcClient = fdcClient
        self.offClient = offClient
    }

    func search(query: String, page: Int) async throws -> [FoodSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        do {
            let fdcResults = try await fdcClient.searchFoods(matching: trimmed, page: page)
            return deduped(fdcResults)
        } catch {
            let offResults = try await offClient.searchFoods(matching: trimmed, page: page)
            return deduped(offResults)
        }
    }

    private func deduped(_ results: [FoodSearchResult]) -> [FoodSearchResult] {
        var seen = Set<String>()
        var unique: [FoodSearchResult] = []

        for item in results {
            if seen.insert(item.id).inserted {
                unique.append(item)
            }
        }

        return unique
    }
}
