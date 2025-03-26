//
//  GeminiService.swift
//  geminate
//
//  Created by Tom David on 3/26/25.
//

import Foundation
import UIKit
import SwiftUI
import Combine

class GeminiService: ObservableObject {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let model = "gemini-2.0-flash-exp-image-generation"
    var cancellables = Set<AnyCancellable>()
    
    // Published properties to track state
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    // MARK: - Image Generation and Editing
    
    func editImage(image: UIImage, prompt: String) -> AnyPublisher<UIImage, Error> {
        isProcessing = true
        errorMessage = nil
        
        let urlString = "\(baseURL)/models/\(model):generateContent?key=\(Secrets.geminiApiKey)"
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "GeminiError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = NSError(domain: "GeminiError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Create the request body for image editing
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [
                    ["text": prompt],
                    ["inlineData": [
                        "mimeType": "image/jpeg",
                        "data": base64Image
                    ]]
                ]]
            ],
            "generationConfig": [
                "responseModalities": ["Text", "Image"]
            ]
        ]
        
        return performRequest(url: url, requestBody: requestBody)
            .map { response -> UIImage in
                self.isProcessing = false
                return response
            }
            .catch { error -> AnyPublisher<UIImage, Error> in
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helpers
    
    private func performRequest(url: URL, requestBody: [String: Any]) -> AnyPublisher<UIImage, Error> {
        let subject = PassthroughSubject<UIImage, Error>()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "GeminiError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                if httpResponse.statusCode != 200 {
                    // Try to parse error message from API response
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw NSError(domain: "GeminiError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                    } else {
                        throw NSError(domain: "GeminiError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])
                    }
                }
                
                return data
            }
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        subject.send(completion: .failure(error))
                    }
                },
                receiveValue: { data in
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let candidates = jsonResponse["candidates"] as? [[String: Any]],
                           let firstCandidate = candidates.first,
                           let content = firstCandidate["content"] as? [String: Any],
                           let parts = content["parts"] as? [[String: Any]] {
                            
                            // Look for inline image data in parts
                            for part in parts {
                                if let inlineData = part["inlineData"] as? [String: Any],
                                   let base64Data = inlineData["data"] as? String,
                                   let imageData = Data(base64Encoded: base64Data),
                                   let image = UIImage(data: imageData) {
                                    
                                    subject.send(image)
                                    subject.send(completion: .finished)
                                    return
                                }
                            }
                        }
                        
                        // If we get here, no image was found in the response
                        subject.send(completion: .failure(NSError(domain: "GeminiError", code: 4, userInfo: [NSLocalizedDescriptionKey: "No image found in response"])))
                    } catch {
                        subject.send(completion: .failure(error))
                    }
                }
            )
            .store(in: &cancellables)
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Helper Types
    
    struct GeminiTextAndImageResponse {
        let text: String?
        let image: UIImage?
    }
    
    func generateTextAndImage(prompt: String, image: UIImage) -> AnyPublisher<GeminiTextAndImageResponse, Error> {
        isProcessing = true
        errorMessage = nil
        
        let urlString = "\(baseURL)/models/\(model):generateContent?key=\(Secrets.geminiApiKey)"
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "GeminiError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            let error = NSError(domain: "GeminiError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Create the request body
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [
                    ["text": prompt],
                    ["inlineData": [
                        "mimeType": "image/jpeg",
                        "data": base64Image
                    ]]
                ]]
            ],
            "generationConfig": [
                "responseModalities": ["Text", "Image"]
            ]
        ]
        
        let subject = PassthroughSubject<GeminiTextAndImageResponse, Error>()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "GeminiError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                if httpResponse.statusCode != 200 {
                    // Try to parse error message from API response
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw NSError(domain: "GeminiError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
                    } else {
                        throw NSError(domain: "GeminiError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])
                    }
                }
                
                return data
            }
            .sink(
                receiveCompletion: { completion in
                    self.isProcessing = false
                    if case let .failure(error) = completion {
                        self.errorMessage = error.localizedDescription
                        subject.send(completion: .failure(error))
                    }
                },
                receiveValue: { data in
                    do {
                        var responseText: String? = nil
                        var responseImage: UIImage? = nil
                        
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let candidates = jsonResponse["candidates"] as? [[String: Any]],
                           let firstCandidate = candidates.first,
                           let content = firstCandidate["content"] as? [String: Any],
                           let parts = content["parts"] as? [[String: Any]] {
                            
                            // Process each part - could be text or image
                            for part in parts {
                                // Check for text
                                if let text = part["text"] as? String {
                                    responseText = text
                                }
                                
                                // Check for image
                                if let inlineData = part["inlineData"] as? [String: Any],
                                   let base64Data = inlineData["data"] as? String,
                                   let imageData = Data(base64Encoded: base64Data),
                                   let image = UIImage(data: imageData) {
                                    responseImage = image
                                }
                            }
                            
                            // Return the combined response
                            let response = GeminiTextAndImageResponse(text: responseText, image: responseImage)
                            subject.send(response)
                            subject.send(completion: .finished)
                            return
                        }
                        
                        // If we get here, no valid response was found
                        subject.send(completion: .failure(NSError(domain: "GeminiError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                    } catch {
                        subject.send(completion: .failure(error))
                    }
                }
            )
            .store(in: &cancellables)
        
        return subject.eraseToAnyPublisher()
    }
}
