import Foundation
import Combine

@MainActor
final class FoodSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [FoodSearchResult] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var canLoadMore: Bool = false

    private let repository: FoodSearchRepository
    private var currentPage: Int = 1

    init(repository: FoodSearchRepository) {
        self.repository = repository
    }

    func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resetState()
            return
        }

        currentPage = 1
        isLoading = true
        errorMessage = nil

        do {
            let firstPage = try await repository.search(query: trimmed, page: currentPage)
            results = firstPage
            canLoadMore = !firstPage.isEmpty
        } catch {
            results = []
            canLoadMore = false
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore() async {
        guard canLoadMore, !isLoading else { return }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resetState()
            return
        }

        isLoading = true
        errorMessage = nil

        let nextPage = currentPage + 1

        do {
            let additional = try await repository.search(query: trimmed, page: nextPage)
            currentPage = nextPage
            results.append(contentsOf: additional)
            if additional.isEmpty {
                canLoadMore = false
            }
        } catch {
            canLoadMore = false
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func resetState() {
        results = []
        canLoadMore = false
        isLoading = false
        errorMessage = nil
    }
}
