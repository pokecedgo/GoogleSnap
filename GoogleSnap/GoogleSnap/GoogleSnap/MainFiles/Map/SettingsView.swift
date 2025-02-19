//
//  SettingsView.swift
//  GoogleSnap
//
//  Created by Cedric Petilos on 1/4/25.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager = DataManager(location: nil)
    @Binding var markers: [Marker] // Add this to receive the markers array
    @State private var userEmail: String? = nil // State to hold the user's email

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                // Display User Email
                if let email = userEmail {
                    Text("Logged in as: \(email)")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    Text("Fetching user email...")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding()
                }

                // Display Total Markers
                VStack(alignment: .leading, spacing: 5) {
                    Text("Markers Summary:")
                        .font(.headline)
                        .padding(.bottom, 5)
                    Text("Cop Markers: \(countMarkers(ofType: "isCop"))")
                    Text("Note Markers: \(countMarkers(ofType: "isNote"))")
                    Text("Image Spots: \(countMarkers(ofType: "isImage"))")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .shadow(radius: 5)

                // Wipe All Data Button
                Button(action: {
                    wipeAllUserData()
                }) {
                    Text("Wipe All User Data")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }

                // Sign Out Button
                Button(action: {
                    signOut()
                }) {
                    Text("Sign Out")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }

                Spacer()
            }
            .padding()
            .onAppear {
                fetchUserEmail() // Fetch the user's email on appear
            }
        }
    }

    private func fetchUserEmail() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email // Fetch the user's email
        } else {
            userEmail = "No email found"
        }
    }

    private func countMarkers(ofType type: String) -> Int {
        return markers.filter { $0.type == type }.count
    }

    private func wipeAllUserData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated.")
            return
        }

        dataManager.deleteAllMarkersGlobally { success in
            if success {
                DispatchQueue.main.async {
                    markers.removeAll() // Clear local markers
                }
                print("All user data wiped successfully.")
                // Fetch fresh markers to reflect the deletion
                dataManager.fetchMarkers(userId: userId) { fetchedMarkers in
                    DispatchQueue.main.async {
                        markers = fetchedMarkers
                    }
                }
            } else {
                print("Failed to wipe user data.")
            }
        }
    }


    private func signOut() {
        do {
            try Auth.auth().signOut()
            print("User signed out successfully.")
            // Navigate to login screen if applicable
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SettingsView(markers: .constant([]))
}
