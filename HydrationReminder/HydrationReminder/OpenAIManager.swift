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
        case addVitamin = "add_vitamin"  // New: create a custom vitamin/supplement
        case unknown = "unknown"
    }

    let type: ActionType
    let details: ActionDetails
    let confidence: Double

    struct ActionDetails: Codable, Equatable {
        let item: String?
        let amount: String?
        let unit: String?
        let calories: String?
        let severity: String?
        let mealType: String?
        let symptoms: [String]?
        let vitaminName: String?
        let notes: String?
        let timestamp: String?  // ISO 8601 format from GPT
        let frequency: String?  // For add_vitamin: "daily", "twice daily", "weekly", etc.
        let dosage: String?  // For add_vitamin: "1 tablet", "500mg", etc.
        let timesPerDay: Int?  // For add_vitamin: how many times per day
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

class OpenAIManager: ObservableObject, @unchecked Sendable {
    nonisolated static let shared = OpenAIManager()
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let whisperURL = "https://api.openai.com/v1/audio/transcriptions"

    @AppStorage("openAIKey") private var apiKey: String = ""
    @Published var isProcessing = false
    @Published var lastError: String?
    @Published var lastTranscription: String?
    @Published var detectedActions: [VoiceAction] = []
    
    private let maxRetries = 3
    private let initialRetryDelay: TimeInterval = 1.0

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
                    ["type": "text", "text": """
Analyze this food image and provide accurate nutritional information.

IMPORTANT GUIDELINES:
- Be REALISTIC with portion sizes - consider typical serving sizes people actually eat
- For prepared dishes, consider all ingredients including oils, butter, sauces
- Don't underestimate - it's better to slightly overestimate than underestimate calories
- Consider cooking methods (fried foods have more calories than steamed)
- Account for condiments, dressings, and toppings visible in the image

For each food item, provide:
- name: Clear descriptive name
- quantity: Realistic portion (e.g., "1 medium plate", "2 slices", "1 cup")
- estimatedCalories: Calories for that portion (be realistic, not conservative)
- protein: grams of protein
- carbs: grams of carbohydrates
- fat: grams of fat
- fiber: grams of fiber

Return JSON format:
{
  "items": [{"name": "...", "quantity": "...", "estimatedCalories": X, "protein": X, "carbs": X, "fat": X, "fiber": X}],
  "totalCalories": X,
  "totalProtein": X,
  "totalCarbs": X,
  "totalFat": X,
  "totalFiber": X
}

Example: A restaurant burger with fries should be 800-1200 calories, not 400.
"""],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                ]
            ]
        ]

        // Define JSON schema for structured output - GUARANTEES format adherence
        let jsonSchema: [String: Any] = [
            "name": "food_analysis_response",
            "strict": true,
            "schema": [
                "type": "object",
                "properties": [
                    "items": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "properties": [
                                "name": ["type": "string"],
                                "quantity": ["type": "string"],
                                "estimatedCalories": ["type": "integer"],
                                "protein": ["type": "number"],
                                "carbs": ["type": "number"],
                                "fat": ["type": "number"],
                                "fiber": ["type": "number"]
                            ],
                            "required": ["name", "quantity", "estimatedCalories", "protein", "carbs", "fat", "fiber"],
                            "additionalProperties": false
                        ]
                    ],
                    "totalCalories": ["type": "integer"],
                    "totalProtein": ["type": "number"],
                    "totalCarbs": ["type": "number"],
                    "totalFat": ["type": "number"],
                    "totalFiber": ["type": "number"]
                ],
                "required": ["items", "totalCalories", "totalProtein", "totalCarbs", "totalFat", "totalFiber"],
                "additionalProperties": false
            ]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-5",  // GPT-5: Best for complex vision and agentic tasks
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 1200,
            "response_format": [
                "type": "json_schema",
                "json_schema": jsonSchema
            ]
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

        print("📸 ============================================")
        print("📸 analyzeFood RESPONSE (STRUCTURED)")
        print("📸 ============================================")
        print("📸 Structured JSON response: '\(text)'")

        // With structured outputs, no cleaning needed - guaranteed valid JSON!
        do {
            let data = text.data(using: .utf8)!
            let result = try JSONDecoder().decode(FoodAnalysis.self, from: data)
            print("📸 ✅ Successfully parsed food analysis!")
            print("📸 Found \(result.items.count) items, Total calories: \(result.totalCalories ?? 0)")
            print("📸 ============================================")
            return result
        } catch {
            print("📸 ❌ UNEXPECTED ERROR - structured outputs should never fail!")
            print("📸 Error: \(error)")
            print("📸 Raw response: \(text)")
            print("📸 ============================================")
            throw OpenAIError.invalidResponse
        }
    }

    func transcribeAudio(audioData: Data) async throws -> VoiceTranscription {
        guard hasAPIKey else {
            throw OpenAIError.noAPIKey
        }

        await MainActor.run {
            self.isProcessing = true
        }
        defer {
            Task { @MainActor in
                self.isProcessing = false
            }
        }

        return try await retryWithExponentialBackoff {
            let boundary = UUID().uuidString
            var request = URLRequest(url: URL(string: self.whisperURL)!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60

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
                if httpResponse.statusCode == 429 {
                    throw OpenAIError.rateLimitExceeded
                } else if httpResponse.statusCode >= 500 {
                    throw OpenAIError.serverError
                } else {
                    throw OpenAIError.httpError(httpResponse.statusCode)
                }
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let text = json?["text"] as? String ?? ""

            return VoiceTranscription(
                text: text,
                duration: json?["duration"] as? Double,
                language: json?["language"] as? String
            )
        }
    }
    
    private func retryWithExponentialBackoff<T>(operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch let error as OpenAIError {
                lastError = error
                
                switch error {
                case .rateLimitExceeded, .serverError:
                    if attempt < maxRetries - 1 {
                        let delay = initialRetryDelay * pow(2.0, Double(attempt))
                        print("🔄 Retry attempt \(attempt + 1)/\(maxRetries) after \(delay)s delay")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                case .networkError:
                    if attempt < maxRetries - 1 {
                        let delay = initialRetryDelay * pow(1.5, Double(attempt))
                        print("🔄 Network retry \(attempt + 1)/\(maxRetries) after \(delay)s delay")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                default:
                    throw error
                }
                
                throw error
            } catch {
                lastError = error
                
                if attempt < maxRetries - 1 {
                    let delay = initialRetryDelay * pow(1.5, Double(attempt))
                    print("🔄 Generic retry \(attempt + 1)/\(maxRetries) after \(delay)s delay")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                throw error
            }
        }
        
        throw lastError ?? OpenAIError.networkError
    }

    func extractVoiceActions(from transcript: String) async throws -> [VoiceAction] {
        guard hasAPIKey else {
            throw OpenAIError.noAPIKey
        }

        await MainActor.run {
            self.isProcessing = true
        }
        defer {
            Task { @MainActor in
                self.isProcessing = false
            }
        }

        let currentDate = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let currentTimestamp = formatter.string(from: currentDate)
        
        // Get current hour for context
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentDate)
        
        let prompt = """
        Analyze this voice transcript and extract any actions the user wants to perform.
        Current timestamp: \(currentTimestamp)
        Current hour: \(currentHour):00

        Return JSON array of actions with type, details, and confidence.

        Types: log_water, log_food, log_symptom, log_vitamin, log_puqe, add_vitamin, unknown

        TIME PARSING RULES - CRITICAL:
        1. ALWAYS include a "timestamp" field in ISO 8601 format
        2. Parse natural language time references:
           
           MEAL TIMES (use these specific hours):
           - "breakfast" or "this morning" -> today at 08:00
           - "lunch" or "midday" -> today at 12:00  
           - "dinner" or "supper" or "this evening" -> today at 18:00
           - "snack" -> use current time unless other context given
           
           RELATIVE TIMES:
           - "just now" or no time mentioned -> use current timestamp
           - "X hours ago" -> subtract X hours from current time
           - "X minutes ago" -> subtract X minutes from current time
           - "earlier" -> subtract 2 hours from current time
           - "this afternoon" -> today at 14:00
           - "last night" -> yesterday at 20:00
           - "yesterday" + meal -> yesterday at meal time
           
           SPECIFIC TIMES:
           - "at 2pm" or "at 14:00" -> today at that time
           - "at 2pm yesterday" -> yesterday at that time
           
        3. For log_food:
           - Put FULL food description including quantity/portion in "item" field
             Examples: "one tiny walnut", "2 slices of pizza", "large bowl of pasta", "small apple"
           - Extract quantity descriptor words (tiny, small, medium, large, huge, handful, etc.)
           - Include the quantity number if mentioned ("1 walnut", "2 eggs", "half an avocado")
           - If meal type mentioned or implied, add "mealType": "breakfast/lunch/dinner/snack"
           - Parse meal times even if just food is mentioned with meal context

           BAD: "item": "walnut" (missing quantity!)
           GOOD: "item": "one tiny walnut" (includes quantity and size)

        4. For log_vitamin: put vitamin/supplement name in "vitaminName" field (logs taking existing vitamin)
        5. For log_water: put amount and unit in details
        6. For log_symptom: put symptoms array in "symptoms" field
        7. For add_vitamin: ONLY use when user wants to ADD/CREATE/SET UP a new vitamin/supplement
           - Put name in "vitaminName" field
           - Extract "frequency": "daily", "twice daily", "three times daily", "weekly", etc.
           - Extract "timesPerDay": 1, 2, 3, etc. (from frequency)
           - Extract "dosage": "1 tablet", "500mg", "2 capsules", etc. (if mentioned)
           - Example: "add my prenatal vitamin I should take it 2x a day"
             -> {"type": "add_vitamin", "details": {"vitaminName": "Prenatal Vitamin", "frequency": "twice daily", "timesPerDay": 2, "dosage": "1 tablet"}, "confidence": 0.9}

        Transcript: "\(transcript)"

        Example responses (note ALL have timestamps and FULL food descriptions):
        - "I ate a potato for breakfast":
          [{"type": "log_food", "details": {"item": "1 medium potato", "mealType": "breakfast", "timestamp": "\(calendar.date(bySettingHour: 8, minute: 0, second: 0, of: currentDate)!.ISO8601Format())"}, "confidence": 0.9}]

        - "I had a small banana for supper":
          [{"type": "log_food", "details": {"item": "1 small banana", "mealType": "dinner", "timestamp": "\(calendar.date(bySettingHour: 18, minute: 0, second: 0, of: currentDate)!.ISO8601Format())"}, "confidence": 0.9}]

        - "I ate one tiny walnut":
          [{"type": "log_food", "details": {"item": "one tiny walnut", "timestamp": "\(currentTimestamp)"}, "confidence": 0.95}]

        - "I had 2 slices of pizza and a large coke":
          [{"type": "log_food", "details": {"item": "2 slices of pizza", "timestamp": "\(currentTimestamp)"}, "confidence": 0.95}, {"type": "log_food", "details": {"item": "1 large coke", "timestamp": "\(currentTimestamp)"}, "confidence": 0.9}]
        
        - "I drank water 2 hours ago":
          [{"type": "log_water", "details": {"amount": "some", "unit": "water", "timestamp": "\(currentDate.addingTimeInterval(-7200).ISO8601Format())"}, "confidence": 0.85}]
        
        - "I took my vitamins this morning":
          [{"type": "log_vitamin", "details": {"vitaminName": "vitamins", "timestamp": "\(calendar.date(bySettingHour: 8, minute: 0, second: 0, of: currentDate)!.ISO8601Format())"}, "confidence": 0.95}]

        - "I ate pasta" (no quantity specified, infer reasonable portion):
          [{"type": "log_food", "details": {"item": "1 bowl of pasta", "timestamp": "\(currentTimestamp)"}, "confidence": 0.9}]

        Return ONLY valid JSON array. Every action MUST have a timestamp field.
        IMPORTANT: Food items MUST include quantity/portion information!
        """

        let messages = [
            ["role": "system", "content": "You are an AI assistant that extracts actions from voice transcripts."],
            ["role": "user", "content": prompt]
        ]

        // Define JSON schema for structured output - GUARANTEES format adherence
        let jsonSchema: [String: Any] = [
            "name": "voice_actions_response",
            "strict": true,
            "schema": [
                "type": "object",
                "properties": [
                    "actions": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "properties": [
                                "type": ["type": "string", "enum": ["log_water", "log_food", "log_symptom", "log_vitamin", "log_puqe", "add_vitamin", "unknown"]],
                                "confidence": ["type": "number", "minimum": 0, "maximum": 1],
                                "details": [
                                    "type": "object",
                                    "properties": [
                                        "item": ["type": "string"],
                                        "amount": ["type": "string"],
                                        "unit": ["type": "string"],
                                        "calories": ["type": "string"],
                                        "severity": ["type": "string"],
                                        "mealType": ["type": "string"],
                                        "symptoms": ["type": "array", "items": ["type": "string"]],
                                        "vitaminName": ["type": "string"],
                                        "notes": ["type": "string"],
                                        "timestamp": ["type": "string"],
                                        "frequency": ["type": "string"],
                                        "dosage": ["type": "string"],
                                        "timesPerDay": ["type": "integer"]
                                    ],
                                    "required": [],
                                    "additionalProperties": false
                                ]
                            ],
                            "required": ["type", "confidence", "details"],
                            "additionalProperties": false
                        ]
                    ]
                ],
                "required": ["actions"],
                "additionalProperties": false
            ]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-5",  // GPT-5: Best for complex voice understanding
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 600,
            "response_format": [
                "type": "json_schema",
                "json_schema": jsonSchema
            ]
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

        print("🎙️ ============================================")
        print("🎙️ extractVoiceActions RESPONSE (STRUCTURED)")
        print("🎙️ ============================================")
        print("🎙️ Transcript: \(transcript)")
        print("🎙️ Structured JSON response: '\(text)'")

        // With structured outputs, no cleaning needed - guaranteed valid JSON!
        do {
            let data = text.data(using: .utf8)!
            // Response is wrapped in {"actions": [...]}
            struct ActionsWrapper: Codable {
                let actions: [VoiceAction]
            }
            let wrapper = try JSONDecoder().decode(ActionsWrapper.self, from: data)
            print("🎙️ ✅ Successfully parsed \(wrapper.actions.count) voice actions!")
            for (index, action) in wrapper.actions.enumerated() {
                print("🎙️   Action \(index + 1): \(action.type.rawValue) (confidence: \(action.confidence))")
            }
            print("🎙️ ============================================")
            return wrapper.actions
        } catch {
            print("🎙️ ❌ UNEXPECTED ERROR - structured outputs should never fail!")
            print("🎙️ Error: \(error)")
            print("🎙️ Raw response: \(text)")
            print("🎙️ ============================================")
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
        Estimate nutritional macros for: "\(foodName)"

        CRITICAL INSTRUCTIONS:
        - Pay CLOSE ATTENTION to quantity descriptors (tiny, small, medium, large, handful, etc.)
        - Pay CLOSE ATTENTION to count numbers (1, 2, half, quarter, etc.)
        - Use USDA/accurate nutritional data
        - Be PRECISE with portions - "one tiny walnut" ≠ "walnut" ≠ "handful of walnuts"

        PORTION SIZE GUIDE:
        - "tiny" or "small" = 50-70% of standard serving
        - "medium" or no descriptor = 100% standard serving
        - "large" or "big" = 150-200% of standard serving
        - "1" or "one" of something = exactly one unit
        - "2" or "two" = exactly two units
        - "handful" = ~1oz or ~28g
        - "bowl" = ~1.5-2 cups
        - "plate" = ~2-3 cups

        EXAMPLES (showing precision):
        - "one tiny walnut" -> 13-18 cal (1 walnut half)
        - "1 medium walnut" -> 26-35 cal (1 whole walnut)
        - "handful of walnuts" -> 180-190 cal (~14 walnut halves)
        - "1 bowl of pasta" -> 350-400 cal (cooked, with sauce assumed)
        - "pasta" or "1 serving pasta" -> 200-220 cal (dry weight equivalent)
        - "2 slices of pizza" -> 550-600 cal (restaurant style)
        - "1 tiny apple" -> 50-60 cal (2.5" diameter)
        - "1 large apple" -> 120-130 cal (3.5" diameter)

        Provide accurate nutritional information for the EXACT portion described.
        """

        let messages = [
            ["role": "system", "content": "You are a nutrition expert that provides accurate macro estimates for foods."],
            ["role": "user", "content": prompt]
        ]

        // Define JSON schema for structured output - GUARANTEES format adherence
        let jsonSchema: [String: Any] = [
            "name": "food_macros_response",
            "strict": true,
            "schema": [
                "type": "object",
                "properties": [
                    "calories": ["type": "integer", "description": "Total calories for the specified portion"],
                    "protein": ["type": "integer", "description": "Protein in grams"],
                    "carbs": ["type": "integer", "description": "Carbohydrates in grams"],
                    "fat": ["type": "integer", "description": "Fat in grams"]
                ],
                "required": ["calories", "protein", "carbs", "fat"],
                "additionalProperties": false
            ]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-5-mini",  // GPT-5 mini: Faster, cost-efficient for well-defined tasks
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 150,
            "response_format": [
                "type": "json_schema",
                "json_schema": jsonSchema
            ]
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

        print("🍔 ============================================")
        print("🍔 estimateFoodMacros RESPONSE (STRUCTURED)")
        print("🍔 ============================================")
        print("🍔 Food name: \(foodName)")
        print("🍔 Structured JSON response: '\(text)'")

        // With structured outputs, no cleaning needed - guaranteed valid JSON!
        do {
            let data = text.data(using: .utf8)!
            let result = try JSONDecoder().decode([String: Int].self, from: data)
            print("🍔 ✅ Successfully parsed structured JSON!")
            print("🍔 Calories: \(result["calories"]!)")
            print("🍔 Protein: \(result["protein"]!)g")
            print("🍔 Carbs: \(result["carbs"]!)g")
            print("🍔 Fat: \(result["fat"]!)g")
            print("🍔 ============================================")

            // No fallbacks needed - structured outputs guarantee all fields exist
            return FoodMacros(
                calories: result["calories"]!,
                protein: result["protein"]!,
                carbs: result["carbs"]!,
                fat: result["fat"]!
            )
        } catch {
            print("🍔 ❌ UNEXPECTED ERROR - structured outputs should never fail!")
            print("🍔 Error: \(error)")
            print("🍔 Raw response: \(text)")
            print("🍔 ============================================")
            throw OpenAIError.invalidResponse
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
            ["role": "system", "content": "You are a nutrition expert specializing in pregnancy nutrition."],
            ["role": "user", "content": prompt]
        ]

        // Define JSON schema for structured output - GUARANTEES format adherence
        let jsonSchema: [String: Any] = [
            "name": "food_suggestions_response",
            "strict": true,
            "schema": [
                "type": "object",
                "properties": [
                    "suggestions": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "properties": [
                                "food": ["type": "string"],
                                "reason": ["type": "string"],
                                "nutritionalBenefit": ["type": "string"],
                                "preparationTip": ["type": "string"],
                                "avoidIfHigh": ["type": "boolean"]
                            ],
                            "required": ["food", "reason", "nutritionalBenefit", "preparationTip", "avoidIfHigh"],
                            "additionalProperties": false
                        ]
                    ]
                ],
                "required": ["suggestions"],
                "additionalProperties": false
            ]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-5-mini",  // GPT-5 mini: Faster, cost-efficient for food suggestions
            "messages": messages,
            "temperature": 0.8,  // Higher creativity for food suggestions
            "max_tokens": 900,
            "response_format": [
                "type": "json_schema",
                "json_schema": jsonSchema
            ]
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

        print("🥗 ============================================")
        print("🥗 generateFoodSuggestions RESPONSE (STRUCTURED)")
        print("🥗 ============================================")
        print("🥗 Nausea level: \(nauseaLevel)/10")
        print("🥗 Structured JSON response: '\(text)'")

        // With structured outputs, no cleaning needed - guaranteed valid JSON!
        do {
            let data = text.data(using: .utf8)!
            // Response is wrapped in {"suggestions": [...]}
            struct SuggestionsWrapper: Codable {
                let suggestions: [FoodSuggestion]
            }
            let wrapper = try JSONDecoder().decode(SuggestionsWrapper.self, from: data)
            print("🥗 ✅ Successfully parsed \(wrapper.suggestions.count) food suggestions!")
            print("🥗 ============================================")
            return wrapper.suggestions
        } catch {
            print("🥗 ❌ UNEXPECTED ERROR - structured outputs should never fail!")
            print("🥗 Error: \(error)")
            print("🥗 Raw response: \(text)")
            print("🥗 ============================================")
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
        case audioTooLarge
        case rateLimitExceeded
        case serverError

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenAI API key is required. Please add your API key in Settings."
            case .invalidResponse:
                return "Received invalid response from OpenAI. Please try again."
            case .httpError(let code):
                return getDetailedHTTPError(code)
            case .apiError(let message):
                return "OpenAI API error: \(message)"
            case .invalidRequest:
                return "The request format was invalid. Please try again."
            case .networkError:
                return "Network connection failed. Please check your internet connection."
            case .audioTooLarge:
                return "Audio file is too large (max 25MB). Please record shorter clips."
            case .rateLimitExceeded:
                return "Too many requests. Please wait a moment before trying again."
            case .serverError:
                return "OpenAI servers are experiencing issues. Please try again in a few minutes."
            }
        }
        
        private func getDetailedHTTPError(_ code: Int) -> String {
            switch code {
            case 400:
                return "Bad request. The audio format may be invalid."
            case 401:
                return "Invalid API key. Please check your OpenAI API key in Settings."
            case 403:
                return "Access forbidden. Your API key may not have permission for this operation."
            case 429:
                return "Rate limit exceeded. You've made too many requests. Please wait and try again."
            case 500, 502, 503, 504:
                return "OpenAI server error (\(code)). The service is temporarily unavailable."
            default:
                return "HTTP error \(code). Please try again later."
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .noAPIKey:
                return "Go to Settings and add your OpenAI API key to enable AI features."
            case .networkError:
                return "Make sure you're connected to the internet and try again."
            case .rateLimitExceeded:
                return "Wait 30-60 seconds before making another request."
            case .audioTooLarge:
                return "Try recording in shorter segments (under 2 minutes)."
            case .httpError(401), .httpError(403):
                return "Verify your API key is correct and has not expired."
            case .serverError, .httpError(500...599):
                return "This is a temporary issue with OpenAI. Try again in 5-10 minutes."
            default:
                return nil
            }
        }
    }
}
