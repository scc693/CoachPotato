import SwiftUI

struct AppNavigation: View {
    var body: some View {
        TabView {
            DashboardRootView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            FoodSearchRootView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
    }
}

#Preview {
    AppNavigation()
        .environmentObject(DIContainer())
}
