import SwiftUI
import UIKit

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataManager = DataManager(location: nil)  // Provide a default location if needed
    @StateObject private var mapViewModel = MapViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                RootView()
                    .environmentObject(dataManager)
                    .environmentObject(mapViewModel)
            }
        }
    }
}
