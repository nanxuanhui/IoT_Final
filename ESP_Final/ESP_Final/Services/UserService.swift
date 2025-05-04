//T2
//UserService.swift

import Foundation

// Service for user registration, login, and session management
class UserService: ObservableObject {
    private let baseURL = "http://172.31.99.212:8888/api" // Base URL for API
    @Published var currentUser: User? // Currently logged-in user
    @Published var error: Error?      // Holds any error that occurs
    
    // Register a new user
    func register(username: String, password: String) async throws -> User {
        let url = URL(string: "\(baseURL)/register")! // Registration endpoint
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // HTTP POST method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Set content type
        
        let body = [
            "username": username,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body) // Encode request body as JSON
        
        let (data, response) = try await URLSession.shared.data(for: request) // Send request
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse // Invalid response
        }
        
        let registerResponse = try JSONDecoder().decode(LoginResponse.self, from: data) // Decode response
        
        if httpResponse.statusCode == 200, let username = registerResponse.username {
            let user = User(username: username)
            DispatchQueue.main.async {
                self.currentUser = user // Update current user on main thread
            }
            return user
        } else if let errorMsg = registerResponse.error {
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg]) // API error
        } else {
            throw NetworkError.serverError(httpResponse.statusCode) // Other server error
        }
    }
    
    // User login
    func login(username: String, password: String) async throws -> User {
        let url = URL(string: "\(baseURL)/login")! // Login endpoint
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // HTTP POST method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Set content type
        
        let body = [
            "username": username,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body) // Encode request body as JSON
        
        let (data, response) = try await URLSession.shared.data(for: request) // Send request
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse // Invalid response
        }
        
        print("Raw login response: \(String(data: data, encoding: .utf8) ?? "nil")") // Debug print
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data) // Decode response
        
        if httpResponse.statusCode == 200, let username = loginResponse.username {
            let user = User(username: username)
            DispatchQueue.main.async {
                self.currentUser = user // Update current user on main thread
            }
            return user
        } else if let errorMsg = loginResponse.error {
            throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg]) // API error
        } else {
            throw NetworkError.serverError(httpResponse.statusCode) // Other server error
        }
    }
    
    // User logout
    func logout() {
        currentUser = nil // Clear current user
    }
}

// Enum for network errors
enum NetworkError: Error {
    case invalidResponse
    case serverError(Int)
    case decodingError
}

// Struct for decoding login/register API responses
struct LoginResponse: Codable {
    let message: String?
    let username: String?
    let error: String?
} 