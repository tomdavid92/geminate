import SwiftUI
import PhotosUI

struct HomeView: View {
    @State private var selectedImage: UIImage?
    @State private var prompt: String = ""
    @State private var showingImagePicker = false
    @State private var showingResultView = false
    
    private let geminateColor = Color(hex: "AEEA00")
    private let subtextColor = Color(hex: "2E7D32")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Image("logo-full")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                    
                    Text("Picture Editing, Made Simple")
                        .font(.custom("Poppins", size: 16).weight(.bold))
                        .foregroundColor(subtextColor)
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                .padding(.horizontal, 40)
                
                VStack(spacing: 30) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    } else {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 40))
                                Text("Select Image")
                                    .font(.headline)
                            }
                            .foregroundColor(.blue)
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Enter your prompt...", text: $prompt)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        
                        Button(action: {
                            if selectedImage != nil && !prompt.isEmpty {
                                showingResultView = true
                            }
                        }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedImage != nil && !prompt.isEmpty ? geminateColor : Color.gray.opacity(0.3))
                                )
                        }
                        .disabled(selectedImage == nil || prompt.isEmpty)
                    }
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.vertical, 20)
            .background(Color.gray.opacity(0.03))
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .fullScreenCover(isPresented: $showingResultView) {
                ResultView(image: selectedImage!, prompt: prompt)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

// Add Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    HomeView()
} 