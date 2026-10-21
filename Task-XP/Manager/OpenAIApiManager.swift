//
//  OpenAIApiManager.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 9/16/26.
//

import Foundation

struct GeneratedTask: Codable {
    let title: String
    let description: String
    let dueAt: Int?
    let dueHasTime: Bool
    let priority: Int
    let difficulty: Int
    let estimatedMinutes: Int?
    let tags: [String]
}

struct ModelsResponse: Codable {
    let data: [OpenAIModel]
}

struct OpenAIModel: Codable, Identifiable {
    let id: String
}

struct OpenAIResponse: Decodable {
    let output: [OutputItem]
}

struct OutputItem: Decodable {
    let content: [OutputContent]?
}

struct OutputContent: Decodable {
    let type: String
    let text: String?
}

struct OpenAIErrorResponse: Decodable {
    let error: OpenAIErrorDetail
}

struct OpenAIErrorDetail: Decodable {
    let message: String
}

final class OpenAIApiManager {
    func isApiKeyValid(apiKey: String) async throws -> Bool {
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        
        return httpResponse.statusCode == 200
    }
    
    func getModels(apiKey: String) async throws -> [OpenAIModel] {
        guard let requestURL = URL(string: "https://api.openai.com/v1/models") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let result = try JSONDecoder().decode(
            ModelsResponse.self, from: data
        )
        
        return result.data
    }
    
    func createTask(apiKey: String, model: String, userInput: String) async throws -> GeneratedTask {
        guard let requestURL = URL(string: "https://api.openai.com/v1/responses") else {
            throw URLError(.badURL)
        }
        
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "title": [
                    "type": "string",
                    "description": "A short and clear task title."
                ],
                "description": [
                    "type": ["string"],
                    "description": "A concise description of the task."
                ],
                "dueAt": [
                    "type": ["integer", "null"],
                    "description": "Unix timestamp in seconds for the due date, or null when no due date can be determined."
                ],
                "dueHasTime": [
                    "type": "boolean",
                    "description": """
                    True if the user specified a specific time, such as 3 PM.
                    False if only a date was specified, such as tomorrow or next Friday.
                    """
                ],
                "priority": [
                    "type": "integer",
                    "description": "Priority from 1 to 5, where 5 is highest."
                ],
                "difficulty": [
                    "type": "integer",
                    "description": "Difficulty from 1 to 5, where 5 is hardest."
                ],
                "estimatedMinutes": [
                    "type": ["integer", "null"],
                    "description": "Estimated time required in minutes, or null if unknown."
                ],
                "tags": [
                    "type": "array",
                    "items": [
                        "type": "string"
                    ],
                    "description": "Short category tags relevant to the task."
                ]
            ],
            "required": [
                "title",
                "description",
                "dueAt",
                "dueHasTime",
                "priority",
                "difficulty",
                "estimatedMinutes",
                "tags"
            ],
            "additionalProperties": false
        ]
        
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current

        let now = formatter.string(from: Date())

        let body: [String: Any] = [
            "model": model,

            "instructions": """
            Convert the user's request into a task for a task-management app.

            Current date and time:
            \(now)

            Interpret relative dates such as today, tomorrow, and next Friday
            using this current date and time.

            Keep the title short.
            Generate useful tags.
            """,

            "input": userInput,

            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "generated_task",
                    "strict": true,
                    "schema": schema
                ]
            ]
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw OpenAIApiError.apiError(errorResponse.error.message)
            }
            throw URLError(.badServerResponse)
        }
        let responseObject = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let outputText = responseObject.output
            .flatMap({ $0.content ?? [] })
            .first(where: { $0.type == "output_text" })?
            .text
        else {
            throw OpenAIApiError.missingOutput
        }
        guard let taskData = outputText.data(using: .utf8) else {
            throw OpenAIApiError.missingOutput
        }
        
        return try JSONDecoder().decode(GeneratedTask.self, from: taskData)
    }
}
