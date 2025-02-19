import FirebaseStorage
import UIKit
import AVFoundation
import PhotosUI

class PhotoHandler: NSObject, ObservableObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let storage = Storage.storage()
    private var completion: ((UIImage?) -> Void)?
    
    // Function to upload image to Firebase and return the URL
    func uploadImageToFirebase(image: UIImage, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error converting image to data")
            return
        }
        
        let imageRef = storage.reference().child("images/\(UUID().uuidString).jpg")
        
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error)")
                return
            }
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error fetching image URL: \(error)")
                    return
                }
                if let url = url {
                    completion(url.absoluteString)
                }
            }
        }
    }
    
    // Open camera to take photo
    func openCamera(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        
        // Check if camera is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera is not available")
            completion(nil)
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    let picker = UIImagePickerController()
                    picker.sourceType = .camera
                    picker.delegate = self
                    picker.allowsEditing = true // Allow user to crop the image
                    if let topController = UIApplication.shared.windows.first?.rootViewController {
                        topController.present(picker, animated: true, completion: nil)
                    }
                } else {
                    print("Camera access denied")
                    completion(nil)
                }
            }
        }
    }
    
    // UIImagePickerControllerDelegate method for handling captured image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        picker.dismiss(animated: true) {
            self.completion?(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.completion?(nil)
        }
    }
}
