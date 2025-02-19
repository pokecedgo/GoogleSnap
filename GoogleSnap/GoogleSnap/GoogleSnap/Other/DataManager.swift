import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import SwiftUI
import CoreLocation
import Foundation


struct Marker: Identifiable, Codable, Equatable {
    let id: UUID
    var documentId: String? // Firestore document ID
    let coordinate: CLLocationCoordinate2D
    let type: String // "isCop", "isNote", or "isImage"
    var note: String? // Custom note for isNote type
    var imageUrls: [String] // Array of image URLs for isImage type

    // Custom Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, type, note, imageUrls
    }

    init(id: UUID, coordinate: CLLocationCoordinate2D, type: String, note: String?, imageUrls: [String]) {
        self.id = id
        self.coordinate = coordinate
        self.type = type
        self.note = note
        self.imageUrls = imageUrls
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        type = try container.decode(String.self, forKey: .type)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        imageUrls = try container.decode([String].self, forKey: .imageUrls)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(type, forKey: .type)
        try container.encode(note, forKey: .note)
        try container.encode(imageUrls, forKey: .imageUrls)
    }

    // Custom Equatable conformance
    static func == (lhs: Marker, rhs: Marker) -> Bool {
        return lhs.id == rhs.id &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.type == rhs.type &&
               lhs.note == rhs.note &&
               lhs.imageUrls == rhs.imageUrls
    }
}


class DataManager: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    @Published var isUserAuthenticated: Bool = false
    @Published var authErrorMessage: String? = nil
    @Published var markers: [Marker] = [] // Store fetched markers

    var location: CLLocationCoordinate2D? // Mutable location

    // Modify the initializer to accept a coordinate
    init(location: CLLocationCoordinate2D?) {
        checkAuthState()
        self.location = location
    }

    // Registration Data
    func checkAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                self.verifyUserInDatabase(userId: user.uid)
            } else {
                self.isUserAuthenticated = false
            }
        }
    }
    
    func createUserInDatabase(userId: String, email: String) {
        let userRef = db.collection("users").document(userId)

        let userData: [String: Any] = [
            "email": email,
            "userId": userId,
            "createdAt": Timestamp(date: Date()) // The current date when the user is created
        ]

        userRef.setData(userData) { error in
            if let error = error {
                print("Error creating user in Firestore: \(error.localizedDescription)")
            } else {
                print("User created successfully in Firestore!")
            }
        }
    }


    private func verifyUserInDatabase(userId: String) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error verifying user in Firestore: \(error.localizedDescription)")
                self.authErrorMessage = "Failed to fetch user data."
                self.isUserAuthenticated = false
                return
            }

            if document?.exists == true {
                self.isUserAuthenticated = true
                self.authErrorMessage = nil
            } else {
                self.authErrorMessage = "User data not found."
                self.isUserAuthenticated = false
            }
        }
    }

    // New method to load currentUserId based on the authenticated user
    func loadCurrentUserId(completion: @escaping (String?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found.")
            completion(nil)
            return
        }

        // Successfully retrieved userId, return it
        print("Current user ID: \(userId)")
        completion(userId)
    }

    // Store user markers
    func saveMarker(viewModel: MapViewModel, userId: String, marker: inout Marker, images: [UIImage] = [], completion: @escaping (Bool) -> Void) {
        // Generate Firestore document reference and ID
        let markerRef = db.collection("users").document(userId).collection("markers").document()
        marker.documentId = markerRef.documentID // Assign Firestore document ID to the marker

        // Prepare marker data
        var markerData: [String: Any] = ["type": marker.type]

        // Validate and assign location coordinates
        if let currentLocation = viewModel.currentLocation {
            let latitude = currentLocation.latitude
            let longitude = currentLocation.longitude

            if isValidCoordinate(latitude: latitude, longitude: longitude) {
                markerData["latitude"] = latitude
                markerData["longitude"] = longitude
                print("Using current location from viewModel: \(latitude), \(longitude)")
            } else {
                print("Error: Invalid current location coordinates from viewModel: \(latitude), \(longitude)")
                completion(false)
                return
            }
        } else if isValidCoordinate(latitude: marker.coordinate.latitude, longitude: marker.coordinate.longitude) {
            // Use marker's provided coordinates
            markerData["latitude"] = marker.coordinate.latitude
            markerData["longitude"] = marker.coordinate.longitude
        } else {
            print("Error: Current location not available, and marker coordinates are invalid.")
            completion(false)
            return
        }

        // Add optional note for "isNote" type markers
        if marker.type == "isNote", let note = marker.note {
            markerData["note"] = note
        }

        print("Attempting to save marker with data: \(markerData)")

        // Save marker data to Firestore
        markerRef.setData(markerData) { error in
            if let error = error {
                print("Error saving marker: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Marker saved successfully into Firestore!")
                completion(true)
            }
        }
    }

    // Helper function to validate coordinates
    private func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
    }


    
    // Update marker's coordinates in Firestore
    func updateMarkerLocation(userId: String, markerId: String, newCoordinate: CLLocationCoordinate2D, completion: @escaping (Bool) -> Void) {
        let markerRef = db.collection("users").document(userId).collection("markers").document(markerId)
        
        let updatedData: [String: Any] = [
            "latitude": newCoordinate.latitude,
            "longitude": newCoordinate.longitude
        ]
        
        markerRef.updateData(updatedData) { error in
            if let error = error {
                print("Error updating marker location: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Marker location updated successfully in Firestore.")
                completion(true)
            }
        }
    }

    func deleteAllMarkersGlobally(completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).collection("markers").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching markers for deletion: \(error)")
                completion(false)
            } else {
                let batch = db.batch()
                snapshot?.documents.forEach { document in
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error committing batch delete: \(error)")
                        completion(false)
                    } else {
                        print("All markers deleted successfully.")
                        completion(true)
                    }
                }
            }
        }
    }

    
    
    //Optimized function for loading user-specific markers from Firestore.
    // This function retrieves only the marker data for the current user and avoids reloading
    // markers already displayed on the map. It ensures data loading efficiency by
    // minimizing unnecessary operations, particularly beneficial for handling large datasets.

    func listenForNewMarkers(userId: String, onMarkerAdded: @escaping (Marker) -> Void) {
        db.collection("users").document(userId).collection("markers").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening for marker updates: \(error)")
                return
            }

            guard let documents = snapshot?.documents else { return }
            for change in snapshot!.documentChanges {
                if change.type == .added {
                    let data = change.document.data()
                    let type = data["type"] as? String ?? ""
                    let latitude = data["latitude"] as? Double ?? 0
                    let longitude = data["longitude"] as? Double ?? 0
                    let note = data["note"] as? String
                    let images = data["images"] as? [String] ?? []

                    let newMarker = Marker(
                        id: UUID(),
                        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                        type: type,
                        note: note,
                        imageUrls: images
                    )

                    onMarkerAdded(newMarker) // Notify the caller about the new marker
                }
            }
        }
    }


   
    // Delete the marker from Firestore
    
    /*
     this only deletes / works sometimes like on every 3-4th delete attempt of a marker
     
     
     */
    func deleteMarker(userId: String, marker: Marker, completion: @escaping (Bool) -> Void) {
        guard let documentId = marker.documentId else {
            print("Marker does not have a valid document ID.")
            completion(false)
            return
        }
        let markerRef = db.collection("users").document(userId).collection("markers").document(documentId)
        markerRef.delete { error in
            if let error = error {
                print("Error deleting marker: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Marker deleted successfully.")
                completion(true)
              
            }
        }
    }

    func fetchMarkers(userId: String, completion: @escaping ([Marker]) -> Void) {
        let markersRef = db.collection("users").document(userId).collection("markers")

        markersRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching markers: \(error.localizedDescription)")
                completion([]) // Return an empty array on failure
                return
            }

            guard let documents = snapshot?.documents else {
                print("No markers found for user: \(userId)")
                completion([]) // Return an empty array if no documents are found
                return
            }

            let markers: [Marker] = documents.compactMap { doc in
                let data = doc.data()
                guard
                    let latitude = data["latitude"] as? Double,
                    let longitude = data["longitude"] as? Double,
                    let type = data["type"] as? String
                else {
                    print("Skipping invalid marker data: \(doc.documentID)")
                    return nil
                }

                var marker = Marker(
                    id: UUID(), // Create a new ID for local representation
                    coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    type: type,
                    note: nil,
                    imageUrls: []
                )
                
                marker.documentId = doc.documentID
                
                // Additional fields for specific marker types (like isNote)
                if type == "isNote", let note = data["note"] as? String {
                    marker.note = note
                }

                // If the marker is of type "isImage", handle imageUrls
                if type == "isImage", let imageUrls = data["imageUrls"] as? [String] {
                    marker.imageUrls = imageUrls
                }

                return marker
            }

            print("Successfully fetched \(markers.count) markers for user: \(userId)")
            completion(markers) // Return the array of markers
        }
    }



  // New method to check if a marker of a specific type can be added
    func canAddMarker(ofType type: String, at coordinate: CLLocationCoordinate2D) -> Bool {
        // Filter markers of the same type and check if any are at the same coordinates
        let existingMarkers = markers.filter { $0.type == type && $0.coordinate.latitude == coordinate.latitude && $0.coordinate.longitude == coordinate.longitude }
        return existingMarkers.isEmpty
    }
}
