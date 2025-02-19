import SwiftUI
import FirebaseAuth
import MapKit
import UIKit
import CoreLocation

struct MapView: View {
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.7209267, longitude: -73.9601382),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    
    @State private var selectedCopMarker: Marker? // Track the selected cop marker


    @State private var note = ""
    @State private var audioHandler = AudioHandler.shared
    @State private var markers: [Marker] = []
    @State private var isShowingOptions = false
    @State private var selectedMarkerType: String?
    @State private var noteText: String = ""
    @State private var showingNoteView = false
    @State private var showingNotePopup = false
    @State private var selectedMarkerNote: String?
    @State private var selectedImageMarker: Marker?
    @State private var photoHandler = PhotoHandler()
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var dataManager = DataManager(location: nil)
    @State private var userId: String = ""  // Store the current user ID
    
    @State private var address: String? = nil
    @State private var isShowingSettings = false

    @State private var userCoordinates: String = "Fetching location..."
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $mapRegion, interactionModes: .all, showsUserLocation: true, annotationItems: markers) { marker in
                    MapAnnotation(coordinate: marker.coordinate) {
                        VStack {
                            // Use MarkerSymbols to display the correct symbol and color based on marker type
                            Image(systemName: marker.type == "isImage" ? MarkerSymbols.imageMarkerSymbol :
                                    (marker.type == "isCop" ? MarkerSymbols.copMarkerSymbol : MarkerSymbols.noteMarkerSymbol))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(marker.type == "isImage" ? MarkerSymbols.imageMarkerColor :
                                                  (marker.type == "isCop" ? MarkerSymbols.copMarkerColor : MarkerSymbols.noteMarkerColor))
                                .padding(4)
                                .background(Circle().fill(Color.white).shadow(radius: 2))
                                .onTapGesture {
                                    if marker.type == "isImage" {
                                        selectedImageMarker = marker
                                        showImageDetail(marker: marker)
                                    } else if marker.type == "isNote" {
                                        fetchAddress(for: marker)
                                    } else if marker.type == "isCop" {
                                        //select cop marker (for deletion ig)
                                        selectedCopMarker = marker
                                              
                                    }
                                }
                          }
                      }
                }
                .accentColor(.orange)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    
                    viewModel.checkLocationServiceStatus()
                    startUpdatingUserCoordinates()
                     
                    
                    if let currentUser = Auth.auth().currentUser {
                        self.userId = currentUser.uid
                        updateMarkers() // Fetch the markers and update the map
                        
                        // Listen for new markers added to the user's collection
                        dataManager.listenForNewMarkers(userId: userId) { newMarker in
                            DispatchQueue.main.async {
                                if !self.markers.contains(where: { $0.id == newMarker.id }) {
                                    self.markers.append(newMarker)
                                }
                            }
                        }
                    } else {
                        print("No user is logged in.")
                    }
                }
                //Nearbys marker Display
                HStack {
                    NearbyMarkersView(
                        mapRegion: $mapRegion,
                        markers: $markers, mapViewModel: viewModel,
                        onMarkerSelected: { marker in
                            if marker.type == "isNote" {
                                fetchAddress(for: marker)
                            } else if marker.type == "isImage" {
                                showImageDetail(marker: marker)
                            }
                        }, viewModel: viewModel
                    )
                    .frame(width: 300, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear)
                            .shadow(radius: 5)
                    )
                    .offset(x: 35, y: -300)
                    .padding(.leading)
                    
                    Spacer()
                }
                .padding(.top)

                // Text Display for Coordinates
                VStack {
                   HStack {
                       Spacer()
            
                       Text(userCoordinates)
                           .font(.system(size: 14, weight: .medium, design: .rounded))
                           .foregroundColor(.white)
                           .padding(10)
                           .background(
                               RoundedRectangle(cornerRadius: 10)
                                .fill(Color.brown.opacity(0.4))
                                   .shadow(radius: 5)
                           )
                           .padding(.top, 50)
                           .offset(x: -100, y: -30)
                   }
                   Spacer()
                }
                //Cop delete button
                if let selectedCopMarker = selectedCopMarker {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                deleteMarker(selectedCopMarker)
                                self.selectedCopMarker = nil // Hide the button after deletion
                            }) {
                                Text("Delete")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                    .shadow(radius: 2)
                            }
                            .position(x: 0, y: 0)
                        }
                    }
                }

                
                // Existing code for displaying detail popups when marker is tapped
                if let marker = markers.first(where: { $0.note == selectedMarkerNote }) {
                    NoteDetailPopup(
                        note: selectedMarkerNote ?? "Default note text",
                        textColor: .black,
                        borderColor: .gray,
                        isShowingSheet: $showingNotePopup,
                        onDelete: {
                            deleteMarker(marker)
                        },
                        dataManager: DataManager(location: viewModel.location.coordinate),
                        location: viewModel.location.coordinate,
                        markerId: marker.id.uuidString,
                        marker: marker
                    )
                }

                if let selectedImageMarker = selectedImageMarker {
                    ImageDetailPopup(marker: selectedImageMarker, onDelete: {
                        deleteMarker(selectedImageMarker)
                    })
                }

                VStack {
                    Spacer()

                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                isShowingSettings.toggle()
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding(.trailing)
                            .offset(x: -10)
                            .padding(.top, -45)
                        }
                        Spacer()
                    }

                    // Navigation to the SettingsView
                    NavigationLink(destination: SettingsView(markers: $markers), isActive: $isShowingSettings) {
                        EmptyView()
                    }

                    Spacer()

                    HStack {
                        Button(action: {
                            audioHandler.playSound(named: "Click", withExtension: "wav")
                            viewModel.centerMapOnUserLocation { location in
                                if let location = location {
                                    DispatchQueue.main.async {
                                        mapRegion.center = location.coordinate
                                        print("User location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                                    }
                                } else {
                                    print("User location not available.")
                                }
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.leading)

                        Spacer()

                        Button(action: {
                            audioHandler.playSound(named: "Click", withExtension: "wav")
                            if isShowingOptions {
                                addCopMarker()
                            } else {
                                photoHandler.openCamera { image in
                                    if let image = image {
                                        uploadImageAndSaveMarker(image: image)
                                    }
                                }
                            }
                        }) {
                            Image(systemName: isShowingOptions ? "shield.fill" : "camera.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.trailing)

                        Button(action: {
                            audioHandler.playSound(named: "Click", withExtension: "wav")
                            if isShowingOptions {
                                showingNoteView.toggle()
                            } else {
                                isShowingOptions.toggle()
                            }
                        }) {
                            Image(systemName: isShowingOptions ? "note.text" : "pin.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.trailing)

                        if isShowingOptions {
                            Button(action: {
                                isShowingOptions.toggle()
                            }) {
                                Image(systemName: "arrow.left.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding(.trailing)
                        }
                    }
                    .padding()
                }

                if showingNoteView {
                    NoteInputView(dataManager: dataManager, note: $note, markers: $markers, viewModel: viewModel) // Pass the markers binding here
                }
            }
        }
    }

    /*
        ============
         Coordinate Display
        ============
     */
    private func startUpdatingUserCoordinates() {
           Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
               if let location = viewModel.currentLocation {
                   DispatchQueue.main.async {
                       self.userCoordinates = String(format: "Lat: %.5f, Lon: %.5f",
                                                     location.latitude,
                                                     location.longitude)
                   }
               } else {
                   DispatchQueue.main.async {
                       self.userCoordinates = "Unable to fetch location"
                   }
               }
           }
       }

    
    // Function to update markers when the map appears or when new markers are added
    private func updateMarkers() {
        dataManager.fetchMarkers(userId: userId) { fetchedMarkers in
            self.markers = fetchedMarkers
        }
    }

    // Function to process the marker type and create the appropriate view
    private func processMarker(marker: Marker) -> some View {
        print(" === PROCESSING FIREBASE FOR MARKERS ===")
        
        let savedCoordinates = marker.coordinate // This is the saved coordinate from Firebase
        let currentCoordinates = viewModel.location.coordinate // This is the current coordinate where the marker is placed
        
        let isNearSavedLocation = isMarkerNearSavedLocation(savedCoordinate: savedCoordinates, currentCoordinate: currentCoordinates)
        
        if !isNearSavedLocation {
            // If not near, move the marker to the saved coordinates
            print("Marker is NOT within 100 meters of the saved location. Moving marker to saved location.")
            moveMarkerToSavedLocation(marker: marker, savedCoordinate: savedCoordinates)
            updateMarkerLocation(marker: marker, newCoordinate: savedCoordinates)
        } else {
            print("Marker is within 100 meters of the saved location.")
        }
        
        let symbolImage: String
        let symbolColor: Color
        
        switch marker.type {
        case "isImage":
            symbolImage = MarkerSymbols.imageMarkerSymbol
            symbolColor = MarkerSymbols.imageMarkerColor
            print("Marker loaded of type: \(marker.type), contents: NA (type Image)")
        case "isCop":
            symbolImage = MarkerSymbols.copMarkerSymbol
            symbolColor = MarkerSymbols.copMarkerColor
            print("Marker loaded of type: \(marker.type), contents: NA (type Cop)")
        case "isNote":
            symbolImage = MarkerSymbols.noteMarkerSymbol
            symbolColor = MarkerSymbols.noteMarkerColor
            print("Marker loaded of type: \(marker.type), contents: \(marker.note ?? "No content")")
        default:
            symbolImage = MarkerSymbols.noteMarkerSymbol // Default fallback
            symbolColor = MarkerSymbols.noteMarkerColor
            print("Marker loaded of type: \(marker.type), contents: NA (unknown type)")
        }

        return Image(systemName: symbolImage)
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .foregroundColor(symbolColor)
            .padding(4)
            .background(Circle().fill(Color.white).shadow(radius: 2))
            .onTapGesture {
                handleMarkerTap(marker: marker)
            }
    }

    // Helper function to check if the current coordinates are near the saved coordinates
    private func isMarkerNearSavedLocation(savedCoordinate: CLLocationCoordinate2D, currentCoordinate: CLLocationCoordinate2D) -> Bool {
        let distanceInMeters = calculateDistance(from: savedCoordinate, to: currentCoordinate)
        return distanceInMeters <= 100 // Threshold of 100 meters
    }

    // Calculate distance between two coordinates
    private func calculateDistance(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        return location1.distance(from: location2) // Returns distance in meters
    }


    // Function to move the marker to its saved location
    private func moveMarkerToSavedLocation(marker: Marker, savedCoordinate: CLLocationCoordinate2D) {
        withAnimation {
            mapRegion.center = savedCoordinate
        }
        
        // Ensure we mutate the markers array correctly
        if let index = markers.firstIndex(where: { $0.id == marker.id }) {
            // Directly update the coordinate
            markers[index] = Marker(id: markers[index].id, coordinate: savedCoordinate, type: markers[index].type, note: markers[index].note, imageUrls: markers[index].imageUrls)
        }
    }

    // Function to update marker location in Firebase
    private func updateMarkerLocation(marker: Marker, newCoordinate: CLLocationCoordinate2D) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }
        
        // Call the method to update the location in Firestore
        dataManager.updateMarkerLocation(userId: userId, markerId: marker.id.uuidString, newCoordinate: newCoordinate) { success in
            if success {
                print("Marker location updated in Firebase.")
            } else {
                print("Failed to update marker location in Firebase.")
            }
        }
    }



    //Cop Marker Handler
    private func addCopMarker() {
        guard let location = viewModel.currentLocation else {
            print("Error: Current location is unavailable")
            return
        }

        // Create a new marker for "Cop"
        var marker = Marker(
            id: UUID(),
            coordinate: location,
            type: "isCop",
            note: nil,
            imageUrls: []
        )

        // Save the marker to Firestore
        dataManager.saveMarker(viewModel: viewModel, userId: userId, marker: &marker) { success in
            if success {
                print("Cop marker added successfully.")
                DispatchQueue.main.async {
                    markers.append(marker) // Update local markers array
                    mapRegion.center = marker.coordinate // Optional: Center map on new marker
                }
            } else {
                print("Failed to add cop marker.")
            }
        }
    }

    // Handle tap events on markers
    private func handleMarkerTap(marker: Marker) {
        if marker.type == "isImage" {
            selectedImageMarker = marker
            showImageDetail(marker: marker)
        } else if marker.type == "isNote" {
            fetchAddress(for: marker)
        }
    }

    private func fetchAddress(for marker: Marker) {
        viewModel.getAddressFromCoordinates(
            latitude: marker.coordinate.latitude,
            longitude: marker.coordinate.longitude
        ) { fetchedAddress in
            DispatchQueue.main.async {
                self.address = fetchedAddress ?? "Unknown location"
                self.selectedMarkerNote = marker.note
                self.showingNotePopup = true
            }
        }
    }

    private func deleteMarker(_ marker: Marker) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user")
            return
        }

        DataManager(location: nil).deleteMarker(userId: userId, marker: marker) { success in
            if success {
                print("Marker deleted from Firebase.")
                if let index = markers.firstIndex(where: { $0.id == marker.id }) {
                    markers.remove(at: index)
                }
                // Update markers after deletion
                updateMarkers()
            } else {
                print("Failed to delete marker.")
            }
        }
    }



    private func showImageDetail(marker: Marker) {
        selectedImageMarker = marker
    }

    private func uploadImageAndSaveMarker(image: UIImage) {
        guard let location = viewModel.currentLocation else {
            print("Error: Current location is unavailable")
            return
        }

        photoHandler.uploadImageToFirebase(image: image) { imageUrl in
            var marker = Marker(
                id: UUID(),
                coordinate: location,
                type: "isImage",
                note: nil,
                imageUrls: [imageUrl]
            )

            DataManager(location: location).saveMarker(viewModel: viewModel, userId: userId, marker: &marker) { success in
                if success {
                    print("Marker saved successfully.")
                } else {
                    print("Failed to save marker.")
                }
            }


            updateMarkers() // Refresh markers after saving the new one
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(
            viewModel: MapViewModel(),
            dataManager: DataManager(location: nil)
        )
        .environmentObject(AudioHandler.shared)
    }
}
