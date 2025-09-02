import Foundation
import SwiftUI

struct FoodAnalysis: Codable {
    let items: [FoodItem]
    let totalCalories: Int?
    let totalProtein: Double?
    let totalCarbs: Double?
    let totalFat: Double?
    let totalFiber: Double?
    
    struct FoodItem: Codable {
        let name: String
        let quantity: String
        let estimatedCalories: Int?
        let protein: Double?
        let carbs: Double?
        let fat: Double?
        let fiber: Double?
    }
}

class OpenAIManager: ObservableObject {
    static let shared = OpenAIManager()
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    @AppStorage("openAIKey") private var apiKey: String = ""
    @Published var isProcessing = false
    @Published var lastError: String?
    
    private init() {}
    
    var hasAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func setAPIKey(_ key: String) {
        apiKey = key
    }
    
    func analyzeFood(imageData: Data) async throws -> FoodAnalysis {
        guard hasAPIKey else {
            throw OpenAIError.noAPIKey
        }
        
        isProcessing = true
        defer { 
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": """
                        Analyze this food image and provide a structured JSON response with the following information:
                        1. Identify all food items visible
                        2. Estimate the quantity/portion size of each item
                        3. Estimate calories for each item
                        4. Estimate macronutrients (protein, carbs, fat, fiber) in grams for each item
                        5. Calculate totals for all items combined
                        
                        Return ONLY valid JSON in this exact format:
                        {
                            "items": [
                                {
                                    "name": "food name",
                                    "quantity": "estimated amount with units",
                                    "estimatedCalories": number or null,
                                    "protein": number or null,
                                    "carbs": number or null,
                                    "fat": number or null,
                                    "fiber": number or null
                                }
                            ],
                            "totalCalories": number or null,
                            "totalProtein": number or null,
                            "totalCarbs": number or null,
                            "totalFat": number or null,
                            "totalFiber": number or null
                        }
                        
                        Be as accurate as possible with your estimates. If you cannot determine a value, use null.
                        """
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.3
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        let cleanedContent = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let contentData = cleanedContent.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        let analysis = try JSONDecoder().decode(FoodAnalysis.self, from: contentData)
        return analysis
    }
    
    enum OpenAIError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case httpError(Int)
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenAI API key not configured. Please add it in Settings."
            case .invalidResponse:
                return "Invalid response from OpenAI"
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .apiError(let message):
                return "API error: \(message)"
            }
        }
    }
}