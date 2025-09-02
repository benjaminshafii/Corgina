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

struct VoiceAction: Codable {
    enum ActionType: String, Codable {
        case logWater = "log_water"
        case logFood = "log_food"
        case logSymptom = "log_symptom"
        case logVitamin = "log_vitamin"
        case logPUQE = "log_puqe"
        case unknown = "unknown"
    }
    
    let type: ActionType
    let details: ActionDetails
    let confidence: Double
    
    struct ActionDetails: Codable {
        let item: String?
        let amount: String?
        let unit: String?
        let severity: String?
        let mealType: String?
        let symptoms: [String]?
        let vitaminName: String?
        let notes: String?
    }
}

struct VoiceTranscription: Codable {
    let text: String
    let duration: Double?
    let language: String?
}

struct FoodSuggestion: Codable {
    let food: String
    let reason: String
    let nutritionalBenefit: String?
    let preparationTip: String?
    let avoidIfHigh: Bool
}

class OpenAIManager: ObservableObject {
    static let shared = OpenAIManager()
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let whisperURL = "https://api.openai.com/v1/audio/transcriptions"
    
    @AppStorage("openAIKey") private var apiKey: String = ""
    @Published var isProcessing = false
    @Published var lastError: String?
    @Published var lastTranscription: String?
    @Published var detectedActions: [VoiceAction] = []
    
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
            "model": "gpt-5",
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
    
    func transcribeAudio(audioData: Data) async throws -> VoiceTranscription {
        guard hasAPIKey else {
            throw OpenAIError.noAPIKey
        }
        
        isProcessing = true
        defer { 
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: whisperURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        DispatchQueue.main.async {
            self.lastTranscription = text
        }
        
        return VoiceTranscription(
            text: text,
            duration: json["duration"] as? Double,
            language: json["language"] as? String
        )
    }
    
    func extractVoiceActions(from transcript: String) async throws -> [VoiceAction] {
        guard hasAPIKey else {
            throw OpenAIError.noAPIKey
        }
        
        isProcessing = true
        defer { 
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        let systemPrompt = """
        You are a pregnancy tracking assistant that extracts structured actions from voice transcripts.
        
        Identify and extract the following types of actions:
        1. Water/drink intake (amount and unit)
        2. Food consumption (what was eaten, meal type)
        3. Symptoms (nausea, headache, fatigue, etc. with severity)
        4. Vitamin/supplement intake (name of vitamin)
        5. PUQE-related symptoms (vomiting, retching, nausea duration)
        
        Return a JSON array of actions. Each action should have:
        - type: "log_water", "log_food", "log_symptom", "log_vitamin", "log_puqe"
        - details: relevant information for that action
        - confidence: 0.0 to 1.0 how confident you are in the interpretation
        
        Example response:
        [
            {
                "type": "log_water",
                "details": {
                    "amount": "16",
                    "unit": "oz"
                },
                "confidence": 0.95
            }
        ]
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Extract actions from: \"\(transcript)\""]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-5",
            "messages": messages,
            "max_tokens": 1000,
            "temperature": 0.2,
            "response_format": ["type": "json_object"]
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
        
        guard let contentData = cleanedContent.data(using: .utf8),
              let actionsJson = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
              let actionsArray = actionsJson["actions"] as? [[String: Any]] ?? actionsJson["data"] as? [[String: Any]] else {
            
            if let singleAction = try? JSONDecoder().decode(VoiceAction.self, from: contentData) {
                DispatchQueue.main.async {
                    self.detectedActions = [singleAction]
                }
                return [singleAction]
            }
            
            throw OpenAIError.invalidResponse
        }
        
        let actions = try actionsArray.compactMap { actionDict -> VoiceAction? in
            guard let actionData = try? JSONSerialization.data(withJSONObject: actionDict) else { return nil }
            return try? JSONDecoder().decode(VoiceAction.self, from: actionData)
        }
        
        DispatchQueue.main.async {
            self.detectedActions = actions
        }
        
        return actions
    }
    
    func transcribeAndExtractActions(audioData: Data) async throws -> [VoiceAction] {
        let transcription = try await transcribeAudio(audioData: audioData)
        return try await extractVoiceActions(from: transcription.text)
    }
    
    func generateFoodSuggestions(puqeScore: Int, recentFoods: [String]) async throws -> [FoodSuggestion] {
        guard hasAPIKey else {
            throw OpenAIError.noAPIKey
        }
        
        let systemPrompt = """
        You are a pregnancy nutrition expert. Based on a PUQE score and recent foods, suggest foods that might help with nausea.
        
        PUQE Score interpretation:
        - 3-6: Mild nausea
        - 7-12: Moderate nausea  
        - 13-15: Severe nausea
        
        Suggest pregnancy-safe foods that are:
        - Easy to digest
        - High in necessary nutrients
        - Known to help with nausea
        - Practical and easy to prepare
        
        Return JSON array with 5 suggestions.
        """
        
        let userPrompt = """
        PUQE Score: \(puqeScore)
        Recent foods that may have triggered symptoms: \(recentFoods.joined(separator: ", "))
        
        Suggest 5 foods that might help. For each include:
        - food: name of the food
        - reason: why it might help
        - nutritionalBenefit: key nutrients
        - preparationTip: how to prepare for maximum benefit
        - avoidIfHigh: true if should avoid with high PUQE
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-5",
            "messages": messages,
            "max_tokens": 1000,
            "temperature": 0.3,
            "response_format": ["type": "json_object"]
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
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        guard let contentData = content.data(using: .utf8),
              let suggestionsJson = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
              let suggestionsArray = suggestionsJson["suggestions"] as? [[String: Any]] ?? suggestionsJson["foods"] as? [[String: Any]] else {
            throw OpenAIError.invalidResponse
        }
        
        let suggestions = try suggestionsArray.compactMap { suggestionDict -> FoodSuggestion? in
            guard let suggestionData = try? JSONSerialization.data(withJSONObject: suggestionDict) else { return nil }
            return try? JSONDecoder().decode(FoodSuggestion.self, from: suggestionData)
        }
        
        return suggestions
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