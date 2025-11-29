import SwiftUI

struct FoodSearchRootView: View {
    @EnvironmentObject private var container: DIContainer

    var body: some View {
        FoodSearchContentView(repository: container.foodSearchRepository)
    }
}

private struct FoodSearchContentView: View {
    @StateObject private var viewModel: FoodSearchViewModel

    init(repository: FoodSearchRepository) {
        _viewModel = StateObject(wrappedValue: FoodSearchViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                searchField

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity, alignment: .center)
                }

                List {
                    ForEach(viewModel.results, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                            if let brand = item.brand, !brand.isEmpty {
                                Text(brand)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if viewModel.canLoadMore {
                        Button(action: {
                            Task { await viewModel.loadMore() }
                        }) {
                            HStack {
                                Spacer()
                                Text("Load more")
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .padding()
            .navigationTitle("Food Search")
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            TextField("Search foods", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.performSearch() }
                }

            Button("Search") {
                Task { await viewModel.performSearch() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    FoodSearchRootView()
        .environmentObject(DIContainer())
}
