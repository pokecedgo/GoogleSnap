import SwiftUI

struct ImageDetailPopup: View {
    var marker: Marker  // Expect a Marker
    var onDelete: () -> Void  // Action when deleting the marker

    var body: some View {
        VStack {
            // Image or details of the marker
            if let imageUrl = marker.imageUrls.first {
                // For simplicity, using the first image URL
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable()
                         .scaledToFit()
                         .frame(width: 200, height: 200)
                } placeholder: {
                    ProgressView()
                }
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.title2)
                    .padding()
                    .background(Color.red)
                    .clipShape(Circle())
                    .foregroundColor(.white)
            }
            .padding()
            
            Button(action: {
                // Close the popup or perform any other action
            }) {
                Text("Close")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())
                    .foregroundColor(.white)
            }
            .padding()
        }
        .background(Color.black.opacity(0.4)) // Darken background for pop-up
        .cornerRadius(10)
        .padding()
    }
}
