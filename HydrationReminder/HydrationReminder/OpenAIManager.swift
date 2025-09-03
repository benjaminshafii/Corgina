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
        
        init(name: String, quantity: String, estimatedCalories: Int? = nil, 
             protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil, 
             fiber: Double? = nil) {
            self.name = name
            self.quantity = quantity
            self.estimatedCalories = estimatedCalories
            self.protein = protein
            self.carbs = carbs
            self.fat = fat
            self.fiber = fiber
        }
        
        enum CodingKeys: String, CodingKey {
            case name, quantity, estimatedCalories, protein, carbs, fat, fiber
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.name = try container.decode(String.self, forKey: .name)
            
            // Handle quantity as either String or Number
            if let quantityString = try? container.decode(String.self, forKey: .quantity) {
                self.quantity = quantityString
            } else if let quantityInt = try? container.decode(Int.self, forKey: .quantity) {
                self.quantity = String(quantityInt)
            } else if let quantityDouble = try? container.decode(Double.self, forKey: .quantity) {
                self.quantity = String(quantityDouble)
            } else {
                self.quantity = "1"  // Default value if parsing fails
            }
            
            self.estimatedCalories = try container.decodeIfPresent(Int.self, forKey: .estimatedCalories)
            self.protein = try container.decodeIfPresent(Double.self, forKey: .protein)
            self.carbs = try container.decodeIfPresent(Double.self, forKey: .carbs)
            self.fat = try container.decodeIfPresent(Double.self, forKey: .fat)
            self.fiber = try container.decodeIfPresent(Double.self, forKey: .fiber)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(quantity, forKey: .quantity)
            try container.encodeIfPresent(estimatedCalories, forKey: .estimatedCalories)
            try container.encodeIfPresent(protein, forKey: .protein)
            try container.encodeIfPresent(carbs, forKey: .carbs)
            try container.encodeIfPresent(fat, forKey: .fat)
            try container.encodeIfPresent(fiber, forKey: .fiber)
        }
    }
}

struct VoiceAction: Codable, Equatable {
    enum ActionType: String, Codable, Equatable {
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

    struct ActionDetails: Codable, Equatable {
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
                    ["type": "text", "text": "Analyze this food image and provide nutritional information. Return JSON with: items array containing food items with name, quantity, estimatedCalories, protein, carbs, fat, fiber. Also include totalCalories, totalProtein, totalCarbs, totalFat, totalFiber."],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                ]
            ]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 1000
        ]

        let data = try JSONSerialization.data(withJSONObject: requestBody)
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.httpError(httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        let content = json?["choices"] as? [[String: Any]]
        let message = content?.first?["message"] as? [String: Any]
        let text = message?["content"] as? String ?? ""

        let cleanedContent = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let data = cleanedContent.data(using: .utf8)!
            return try JSONDecoder().decode(FoodAnalysis.self, from: data)
        } catch let decodingError as DecodingError {
            print("JSON parsing error: \(decodingError)")
            print("Content being parsed: \(cleanedContent)")
            
            // Try to provide a fallback response
            if cleanedContent.contains("items") {
                // Create a basic fallback response
                return FoodAnalysis(
                    items: [FoodAnalysis.FoodItem(
                        name: "Food item",
                        quantity: "1",
                        estimatedCalories: nil,
                        protein: nil,
                        carbs: nil,
                        fat: nil,
                        fiber: nil
                    )],
                    totalCalories: nil,
                    totalProtein: nil,
                    totalCarbs: nil,
                    totalFat: nil,
                    totalFiber: nil
                )
            }
            throw OpenAIError.invalidResponse
        } catch {
            print("Unexpected error: \(error)")
            throw OpenAIError.invalidResponse
        }
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

        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.httpError(httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let text = json?["text"] as? String ?? ""

        return VoiceTranscription(
            text: text,
            duration: json?["duration"] as? Double,
            language: json?["language"] as? String
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

        let prompt = """
        Analyze this voice transcript and extract any actions the user wants to perform.
        Return JSON array of actions with type, details, and confidence.

        Types: log_water, log_food, log_symptom, log_vitamin, log_puqe, unknown

        For log_water: put amount and unit in details
        For log_food: put food name in "item" field in details
        For log_vitamin: put vitamin name in "vitaminName" field in details  
        For log_symptom: put symptoms array in "symptoms" field in details

        Transcript: "\(transcript)"

        Example responses:
        - Water: [{"type": "log_water", "details": {"amount": "8", "unit": "oz"}, "confidence": 0.9}]
        - Food: [{"type": "log_food", "details": {"item": "chicken sandwich", "mealType": "lunch"}, "confidence": 0.85}]
        - Vitamin: [{"type": "log_vitamin", "details": {"vitaminName": "prenatal vitamin"}, "confidence": 0.95}]
        """

        let messages = [
            ["role": "system", "content": "You are an AI assistant that extracts actions from voice transcripts. Always respond with valid JSON only."],
            ["role": "user", "content": prompt]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 500
        ]

        let data = try JSONSerialization.data(withJSONObject: requestBody)
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.httpError(httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        let content = json?["choices"] as? [[String: Any]]
        let message = content?.first?["message"] as? [String: Any]
        let text = message?["content"] as? String ?? ""

        let cleanedContent = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let data = cleanedContent.data(using: .utf8)!
            return try JSONDecoder().decode([VoiceAction].self, from: data)
        } catch {
            print("JSON parsing error: \(error)")
            print("No actions could be extracted from: \(cleanedContent)")
            return []
        }
    }

    struct FoodMacros {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
    }

    func estimateFoodMacros(foodName: String) async throws -> FoodMacros {
        guard hasAPIKey else {
            throw OpenAIError.noAPIKey
        }

        let prompt = """
        Estimate the nutritional macros for: \(foodName)

        Provide estimates for a typical serving size. Return JSON with:
        {
            "calories": 250,
            "protein": 20,
            "carbs": 30,
            "fat": 8
        }

        Provide reasonable estimates based on typical portion sizes.
        """

        let messages = [
            ["role": "system", "content": "You are a nutrition expert that provides accurate macro estimates for foods. Always respond with valid JSON only."],
            ["role": "user", "content": prompt]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 200
        ]

        let data = try JSONSerialization.data(withJSONObject: requestBody)
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.httpError(httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        let content = json?["choices"] as? [[String: Any]]
        let message = content?.first?["message"] as? [String: Any]
        let text = message?["content"] as? String ?? ""

        let cleanedContent = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let data = cleanedContent.data(using: .utf8)!
            let result = try JSONDecoder().decode([String: Int].self, from: data)
            return FoodMacros(
                calories: result["calories"] ?? 100,
                protein: result["protein"] ?? 5,
                carbs: result["carbs"] ?? 10,
                fat: result["fat"] ?? 3
            )
        } catch {
            print("JSON parsing error: \(error)")
            // Return default values if parsing fails
            return FoodMacros(calories: 100, protein: 5, carbs: 10, fat: 3)
        }
    }

    func generateFoodSuggestions(nauseaLevel: Int, preferences: [String] = []) async throws -> [FoodSuggestion] {
        guard hasAPIKey else {
            throw OpenAIError.noAPIKey
        }

        let prompt = """
        Suggest foods for a pregnant person with nausea level \(nauseaLevel)/10.
        Consider these preferences: \(preferences.joined(separator: ", "))

        Return 5 food suggestions in JSON format with:
        - food: name of the food
        - reason: why it's good for nausea
        - nutritionalBenefit: key nutrients
        - preparationTip: how to prepare it
        - avoidIfHigh: true if should avoid with high nausea
        """

        let messages = [
            ["role": "system", "content": "You are a nutrition expert specializing in pregnancy nutrition. Always respond with valid JSON only."],
            ["role": "user", "content": prompt]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 800
        ]

        let data = try JSONSerialization.data(withJSONObject: requestBody)
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.httpError(httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        let content = json?["choices"] as? [[String: Any]]
        let message = content?.first?["message"] as? [String: Any]
        let text = message?["content"] as? String ?? ""

        let cleanedContent = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let data = cleanedContent.data(using: .utf8)!
            return try JSONDecoder().decode([FoodSuggestion].self, from: data)
        } catch {
            print("JSON parsing error: \(error)")
            return []
        }
    }

    enum OpenAIError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case httpError(Int)
        case apiError(String)
        case invalidRequest
        case networkError

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenAI API key is required"
            case .invalidResponse:
                return "Invalid response from OpenAI API"
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .apiError(let message):
                return "API error: \(message)"
            case .invalidRequest:
                return "Invalid request"
            case .networkError:
                return "Network error occurred"
            }
        }
    }
}