import SwiftUI
import PhotosUI

struct ResultView: View {
    let image: UIImage
    let prompt: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveSuccess = false
    @State private var showingImagePicker = false
    @State private var newPrompt: String = ""
    @State private var showingNewPrompt = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                
                VStack(spacing: 15) {
                    Button(action: {
                        showingNewPrompt = true
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Edit Again")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        showingSaveSuccess = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save to Gallery")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "house")
                            Text("Back to Home")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Result")
            .alert("Image Saved", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your image has been saved to your photo gallery.")
            }
            .sheet(isPresented: $showingNewPrompt) {
                NavigationView {
                    VStack(spacing: 20) {
                        TextField("Enter new prompt...", text: $newPrompt)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        
                        Button(action: {
                            // Here we would normally make the API call
                            // For now, we'll just dismiss the sheet
                            showingNewPrompt = false
                        }) {
                            Text("Apply Changes")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .disabled(newPrompt.isEmpty)
                        
                        Spacer()
                    }
                    .navigationTitle("Edit Again")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingNewPrompt = false
                    })
                }
            }
        }
    }
}

#Preview {
    ResultView(image: UIImage(systemName: "photo")!, prompt: "Sample prompt")
} 