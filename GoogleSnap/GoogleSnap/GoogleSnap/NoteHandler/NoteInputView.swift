import SwiftUI
import CoreLocation
import FirebaseAuth

// The NoteInputView with @ObservedObject for dataManager
struct NoteInputView: View {
    @ObservedObject var dataManager: DataManager
    @State private var audioHandler = AudioHandler.shared
    @State private var noteText: String = ""
    @State private var isSheetPresented: Bool = true
    @State private var showError: Bool = false
    @Binding var note: String
    @Binding var markers: [Marker]
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    @State private var isShowingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Nothing here, only sheet logic
        }
        .background(Color.white) // Permanent background color
        .sheet(isPresented: $isSheetPresented, onDismiss: {
            print("Sheet dismissed")
        }) {
            VStack {
                Text("Note")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .padding(.top, 10)

                Spacer()

                ZStack {
                    if noteText.isEmpty {
                        Text("Write your note here...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 5)
                            .padding(.top, 8)
                    }
                    TextEditor(text: $noteText)
                        .padding(16)
                        .background(Color.white) // Permanent background color for TextEditor
                        .cornerRadius(8)
                        .foregroundColor(.black)
                        .frame(height: 150)
                        .padding(.horizontal)
                        .shadow(color: .gray, radius: 5, x: 0, y: 2)
                }

                if showError {
                    Text("Note cannot be empty!")
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }

                Spacer()

                HStack(spacing: 20) {
                    Button(action: {
                        guard let userId = Auth.auth().currentUser?.uid else {
                            alertTitle = "Error"
                            alertMessage = "Unable to retrieve user ID. Please log in again."
                            isShowingAlert = true
                            return
                        }

                        if !dataManager.canAddMarker(ofType: "isNote", at: coordinate) {
                            alertTitle = "Note Exists"
                            alertMessage = "A note already exists at this location."
                            isShowingAlert = true
                            return
                        }

                        audioHandler.playSound(named: "Chime", withExtension: "wav")

                        var marker = Marker(
                            id: UUID(),
                            coordinate: coordinate,
                            type: "isNote",
                            note: noteText,
                            imageUrls: []
                        )

                        dataManager.saveMarker(viewModel: viewModel, userId: userId, marker: &marker) { success in
                            if success {
                                print("Marker saved successfully.")
                            } else {
                                print("Failed to save marker.")
                            }
                        }

                        

                        isSheetPresented = false
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                            Text("Drop Note")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(noteText.isEmpty ? Color.gray : Color.brown)
                        .cornerRadius(10)
                    }
                    .disabled(noteText.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding()
            .background(Color.white) // Ensure sheet background is permanently white
            .colorScheme(.light) // Enforce light mode for the sheet
            .onDisappear {
                isSheetPresented = false
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

// The ParentView which passes dataManager to the NoteInputView
struct ParentView: View {
    @State private var isSheetPresented: Bool = false
    @ObservedObject var dataManager = DataManager(location: nil)
    @State private var noteText: String = ""
    @State private var markers: [Marker] = []

    var body: some View {
        Button("Add Note") {
            isSheetPresented = true
        }
        .sheet(isPresented: $isSheetPresented) {
            NoteInputView(dataManager: dataManager, note: $noteText, markers: $markers, viewModel: MapViewModel())
        }
    }
}

struct ParentView_Previews: PreviewProvider {
    static var previews: some View {
        ParentView()
    }
}
