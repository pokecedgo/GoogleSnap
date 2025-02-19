import SwiftUI

struct RootView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var mapViewModel: MapViewModel
    @State private var showAlert = false  // Tracks whether the alert should be shown
    
    var body: some View {
        Group {
            if dataManager.isUserAuthenticated {
                MapView(viewModel: mapViewModel)
                    .environmentObject(dataManager)
            } else {
                RegistrationView()
                    .environmentObject(dataManager)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Authentication Error"),
                            message: Text(dataManager.authErrorMessage ?? "Unknown error"),
                            dismissButton: .default(Text("OK"))
                        )
                    }
            }
        }
        .onAppear {
            dataManager.checkAuthState()
            
            // Show alert if there's an auth error
            if dataManager.authErrorMessage != nil {
                showAlert = true
            }
        }
    }
}
