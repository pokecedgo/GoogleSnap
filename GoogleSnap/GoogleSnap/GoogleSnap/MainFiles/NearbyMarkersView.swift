import SwiftUI
import MapKit
import FirebaseFirestore

struct NearbyMarkersView: View {
    @Binding var mapRegion: MKCoordinateRegion
    @Binding var markers: [Marker]
    @ObservedObject var mapViewModel: MapViewModel

    @State private var randomMarkers: [Marker] = []

    var onMarkerSelected: (Marker) -> Void
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var dataManager = DataManager(location: nil)

    var body: some View {
        HStack {
            Image(systemName: "airtag")
                .resizable()
                .frame(width: 30, height: 30)  // Adjust size
                .foregroundColor(.white)  // Customize color
         
                HStack(spacing: -100) {
                    ForEach(randomMarkers) { marker in
                        Button(action: {
                            onMarkerSelected(marker)
                        }) {
                            HStack {
                                Image(systemName: marker.type == "isNote" ? "note.text" : "photo")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(marker.type == "isNote" ? .white : .gray)

                                Spacer()
                            }
                          
                            
                        }
                    }
                }
                .padding(.horizontal)
            
        }
        .onAppear {
            // Make sure to call loadCurrentUserId from DataManager
            dataManager.loadCurrentUserId { userId in
                guard let userId = userId else {
                    print("Failed to load userId")
                    return
                }
                print("Random markers[] : Loaded userId: \(userId)")
                self.fetchRandomMarkers()  // Assuming this method fetches the random markers for the user
            }
        }
    }

    private func fetchRandomMarkers() {
        print("Fetching Random Markers 2 ...")
        
        // Use DataManager's loadCurrentUserId to get the userId
        dataManager.loadCurrentUserId { userId in
            guard let userId = userId else {
                print("No user ID found")
                return
            }

            print("User ID: \(userId)")

            // Use DataManager's fetchMarkers method
            dataManager.fetchMarkers(userId: userId) { fetchedMarkers in
                // Filter markers by type
                let filteredMarkers = fetchedMarkers.filter { $0.type == "isNote" || $0.type == "isImage" }

                // Shuffle and take up to 4 markers
                let selectedMarkers = Array(filteredMarkers.shuffled().prefix(4))

                DispatchQueue.main.async {
                    self.randomMarkers = selectedMarkers
                }
            }
        }
    }

}
