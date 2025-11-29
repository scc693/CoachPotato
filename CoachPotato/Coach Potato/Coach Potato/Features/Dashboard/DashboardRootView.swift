import SwiftUI

struct DashboardRootView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Coach Potato Dashboard (Stage 1 Skeleton)")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("Add widgets and trends here in later stages.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    DashboardRootView()
}
