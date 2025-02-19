import SwiftUI
import FirebaseAuth
import CoreLocation

struct NoteDetailPopup: View {
    var note: String
    var textColor: Color
    var borderColor: Color
    @Binding var isShowingSheet: Bool
    var onDelete: () -> Void
    var dataManager: DataManager
    var location: CLLocationCoordinate2D?
    var markerId: String
    var marker: Marker?
    

    @State private var nearestLocation: String = "Unknown Location"


    var locationInfo: String? {
        guard let location = location else { return nil }
        return "Lat: \(location.latitude), Long: \(location.longitude)"
    }

    func findNearestLocation() {
        guard let location = location else {
            print("Location is nil.")
            nearestLocation = "Location not available"
            return
        }

        // Delay implementation
        let delayInSeconds: TimeInterval = 1.5 // Adjust the delay based on the limit (e.g., 50 requests per 60 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
            let geocoder = CLGeocoder()
            let coordinates = CLLocation(latitude: location.latitude, longitude: location.longitude)

            geocoder.reverseGeocodeLocation(coordinates) { (placemarks, error) in
                if let error = error {
                    print("Error in reverse geocoding: \(error.localizedDescription)")
                    nearestLocation = "Location not found"
                    return
                }

                if let placemark = placemarks?.first {
                    if let name = placemark.name {
                        nearestLocation = " 📍\(name)"
                    } else {
                        nearestLocation = "Location not available"
                    }
                } else {
                    nearestLocation = "Location not found"
                }
            }
        }
    }

    var body: some View {
        VStack {
            VStack() {
                // nothing here
            }
            .background(Color.white) // Permanent background color
            .sheet(isPresented: $isShowingSheet, onDismiss: {
                print("Sheet dismissed")
            }) {
                // App Logo
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .cornerRadius(10)
                    .shadow(radius: 10)

                // Note Title
                Text("Note Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)

                // Note Content
                VStack(spacing: 2) {
                    Text("📝 \(note)")
                        .font(.body)
                        .foregroundColor(.black)  // Dynamic text color (light/dark mode)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .frame(maxHeight: 200)
                        .lineLimit(nil)
                }

                // Location Information
                if let location = location {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Dropped Near")
                            .font(.subheadline)
                            .foregroundColor(.black)

                        Text(nearestLocation)
                            .font(.body)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 30) {

                    Button(action: {
                        guard let userId = Auth.auth().currentUser?.uid else {
                            print("User not authenticated.")
                            return
                        }
                        print("===Current Variable Marker ID ====")
                        print(markerId)
                        print("==================================")
                        
                        // Start deletion action
                     
                        if let uuid = UUID(uuidString: markerId) {
                            dataManager.deleteMarker(userId: userId, marker: marker!) { success in
                                DispatchQueue.main.async {
                                    isShowingSheet = false
                                }
                            }
                        } else {
                            print("Invalid markerId format. Unable to convert to UUID.")
                        }


                    }) {
                        HStack {
                            Image(systemName: "trash.circle")
                                .foregroundColor(.white)
                            Text("Delete")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.brown)
                        .cornerRadius(10)
                    }
    
                    Button(action: {
                        // Dismiss the sheet immediately when closing
                        isShowingSheet = false
                        print("Popup closed")
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                            Text("Close")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.brown)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
            }
        }
        .background(Color.white) // Ensure sheet background is permanently white
        .colorScheme(.light)
        .onAppear {
            findNearestLocation()
        }
        .onDisappear {
            isShowingSheet = false
        }
        
    }
}

struct ContentView: View {
    @State private var isShowingSheet = false
    @State private var note = "This is a detailed note for the marker. This is a detailed note for the marker"
    @State private var markerId = "sampleMarkerId123"
    @StateObject var viewModel = MapViewModel()

    var body: some View {
        VStack {
            Button("Show Note Details") {
                if !isShowingSheet { // Ensure sheet isn't already being presented
                    isShowingSheet.toggle()
                }
            }
            .sheet(isPresented: $isShowingSheet) {
                NoteDetailPopup(
                    note: note,
                    textColor: .black,
                    borderColor: .gray,
                    isShowingSheet: $isShowingSheet,
                    onDelete: {
                        print("Delete action triggered")
                    },
                    dataManager: DataManager(location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
                    location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    markerId: markerId
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it fills the sheet
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
