import Foundation
import Combine

/// Simple dependency injection container we can grow in later stages.
/// Stage 2 wires protocol-based defaults for HTTP and search clients.
final class DIContainer: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    let httpClient: HTTPClient
    let fdcClient: FDCClient
    let offClient: OFFClient
    let foodSearchRepository: FoodSearchRepository

    init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        fdcClient: FDCClient = StubFDCClient(),
        offClient: OFFClient = StubOFFClient(),
        foodSearchRepository: FoodSearchRepository? = nil
    ) {
        self.httpClient = httpClient
        self.fdcClient = fdcClient
        self.offClient = offClient
        if let foodSearchRepository {
            self.foodSearchRepository = foodSearchRepository
        } else {
            self.foodSearchRepository = RemoteFoodSearchRepository(
                fdcClient: fdcClient,
                offClient: offClient
            )
        }
    }
}
