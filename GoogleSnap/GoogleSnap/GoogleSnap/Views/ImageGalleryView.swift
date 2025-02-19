import SwiftUI

struct ImageGalleryView: View {
    var marker: Marker

    var body: some View {
        List(marker.imageUrls, id: \.self) { imageUrl in
            AsyncImage(url: URL(string: imageUrl)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView()
            }
        }
        .navigationTitle("Photo Gallery")
    }
}


