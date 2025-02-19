import Foundation
import CoreLocation
import SwiftUI

class ViewModel: ObservableObject {
    @Published var location: CLLocation

    init(location: CLLocation) {
        self.location = location
    }
}


class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationManager: CLLocationManager?
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var isLocationServiceEnabled: Bool = false
    @Published var isLocationAuthorized: Bool = false
    @Published var locationError: String?

    @Published var location: CLLocation
    var currentUserId: String? 
    
    var coordinate: CLLocationCoordinate2D {
        location.coordinate
    }

    override init() {
        self.locationManager = CLLocationManager() // Initialize the location manager
        self.location = CLLocation(latitude: 37.7749, longitude: -122.4194) // Default value
        super.init()
        self.locationManager?.delegate = self // Assign the delegate
        self.locationManager?.requestWhenInUseAuthorization()
    }


    func checkLocationAuthorizationStatus() {
        guard let manager = locationManager else { return }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationAuthorized = true
            isLocationServiceEnabled = true
            manager.startUpdatingLocation()
        case .denied, .restricted:
            isLocationAuthorized = false
            isLocationServiceEnabled = false
            locationError = "Location access denied. Please allow location access in settings."
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            locationError = "Unknown location authorization status."
        }
    }

    func startLocationUpdates() {
        if isLocationAuthorized {
            locationManager?.startUpdatingLocation()
        }
    }

    func stopLocationUpdates() {
        locationManager?.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        self.location = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = "Failed to get user location: \(error.localizedDescription)"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorizationStatus()
    }

    func getAddressFromCoordinates(latitude: Double, longitude: Double, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            if let placemark = placemarks?.first {
                var addressComponents = [String]()
                if let subThoroughfare = placemark.subThoroughfare {
                    addressComponents.append(subThoroughfare)
                }
                if let thoroughfare = placemark.thoroughfare {
                    addressComponents.append(thoroughfare)
                }
                DispatchQueue.main.async {
                    completion(addressComponents.isEmpty ? "Unknown location" : addressComponents.joined(separator: " "))
                }
            } else {
                DispatchQueue.main.async {
                    completion("Unknown location")
                }
            }
        }
    }

    func centerMapOnUserLocation(completion: @escaping (CLLocation?) -> Void) {
        guard let locationManager = locationManager else {
            completion(nil)
            return
        }

        if let location = locationManager.location {
            completion(location)
        } else {
            locationManager.requestLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion(locationManager.location) // Allow time for `requestLocation` to update
            }
        }
    }
    
    func checkLocationServiceStatus() {
        // Check if location services are enabled
        guard CLLocationManager.locationServicesEnabled() else {
            isLocationServiceEnabled = false
            locationError = "Location services are not enabled. Please enable them in settings."
            return
        }
        
        // Update the state
        isLocationServiceEnabled = true
        
        // Check the authorization status
        if let manager = locationManager {
            checkLocationAuthorizationStatus()
        } else {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            checkLocationAuthorizationStatus()
        }
    }

}
