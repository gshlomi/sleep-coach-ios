//
//  APIService.swift
//  SleepCoach
//
//  Network service for communicating with the backend API
//

import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL: String
    private let session: URLSession
    
    private init() {
        // Use localhost for simulator, adjust for device
        #if targetEnvironment(simulator)
        self.baseURL = "http://localhost:3000"
        #else
        self.baseURL = "https://api.sleepcoach.app"
        #endif
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication
    
    func register(
        email: String,
        password: String,
        name: String? = nil,
        plannedBedtime: String? = nil,
        plannedWakeTime: String? = nil,
        sleepGoalHours: Double? = nil
    ) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "name": name as Any,
            "plannedBedtime": plannedBedtime as Any,
            "plannedWakeTime": plannedWakeTime as Any,
            "sleepGoalHours": sleepGoalHours as Any,
            "language": UserDefaults.standard.string(forKey: "appLanguage") ?? "he"
        ].compactMapValues { $0 }
        
        return try await post("/api/users/register", body: body, authenticated: false)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        return try await post("/api/users/login", body: body, authenticated: false)
    }
    
    // MARK: - Sleep Logs
    
    func getSleepLogs(limit: Int = 30, offset: Int = 0) async throws -> SleepLogsResponse {
        return try await get("/api/sleep/logs?limit=\(limit)&offset=\(offset)")
    }
    
    func createSleepLog(_ request: CreateSleepLogRequest) async throws -> SleepLogResponse {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(request)
        let body = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        return try await post("/api/sleep/logs", body: body, authenticated: true)
    }
    
    func deleteSleepLog(id: String) async throws {
        let _: EmptyResponse = try await delete("/api/sleep/logs/\(id)")
    }
    
    func recordTaskCompletion(taskType: String, sleepLogId: String? = nil) async throws {
        var body: [String: Any] = ["taskType": taskType]
        if let logId = sleepLogId {
            body["sleepLogId"] = logId
        }
        
        let _: EmptyResponse = try await post("/api/sleep/tasks/complete", body: body, authenticated: true)
    }
    
    // MARK: - Insights
    
    func getSummary() async throws -> SummaryResponse {
        return try await get("/api/insights/summary")
    }
    
    func getWeeklyAnalysis() async throws -> WeeklyAnalysisResponse {
        return try await get("/api/insights/weekly")
    }
    
    func getMonthlyAnalysis() async throws -> WeeklyAnalysisResponse {
        return try await get("/api/insights/monthly")
    }
    
    func getRecommendations() async throws -> RecommendationsResponse {
        return try await get("/api/insights/recommendations")
    }
    
    // MARK: - HTTP Methods
    
    private func get<T: Decodable>(_ path: String, authenticated: Bool = true) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if authenticated, let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    private func post<T: Decodable>(_ path: String, body: [String: Any], authenticated: Bool = true) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if authenticated, let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    private func delete<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

struct EmptyResponse: Decodable {}
