import SwiftUI
import PhotosUI
import Combine

struct ResultView: View {
    let image: UIImage
    let prompt: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveSuccess = false
    @State private var showingImagePicker = false
    @State private var newPrompt: String = ""
    @State private var showingNewPrompt = false
    @State private var processedImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Initialize the GeminiService
    @StateObject private var geminiService = GeminiService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Processing image...")
                        .frame(maxHeight: 400)
                } else {
                    Image(uiImage: processedImage ?? image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .cornerRadius(12)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
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
                        UIImageWriteToSavedPhotosAlbum(processedImage ?? image, nil, nil, nil)
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
                .disabled(isLoading)
                
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
                            applyNewPrompt()
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
            .onAppear {
                // Process image with Gemini when view appears
                processImageWithGemini()
            }
        }
    }
    
    // Process the image with Gemini when the view loads
    private func processImageWithGemini() {
        guard Secrets.geminiApiKey != "YOUR_API_KEY_HERE" else {
            errorMessage = "Please set up your Gemini API key in Secrets.swift"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        geminiService.editImage(image: image, prompt: prompt)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case let .failure(error) = completion {
                        errorMessage = "Error: \(error.localizedDescription)"
                    }
                },
                receiveValue: { processedImg in
                    processedImage = processedImg
                    isLoading = false
                }
            )
            .store(in: &geminiService.cancellables)
    }
    
    // Apply a new prompt to the current image
    private func applyNewPrompt() {
        guard Secrets.geminiApiKey != "YOUR_API_KEY_HERE" else {
            errorMessage = "Please set up your Gemini API key in Secrets.swift"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Use the processed image if it exists, otherwise use the original
        let sourceImage = processedImage ?? image
        
        geminiService.editImage(image: sourceImage, prompt: newPrompt)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case let .failure(error) = completion {
                        errorMessage = "Error: \(error.localizedDescription)"
                    }
                },
                receiveValue: { processedImg in
                    processedImage = processedImg
                    isLoading = false
                }
            )
            .store(in: &geminiService.cancellables)
    }
}

#Preview {
    ResultView(image: UIImage(systemName: "photo")!, prompt: "Sample prompt")
}
