//T2
//User.swift

import Foundation

// Model representing a user
struct User: Codable {
    let username: String // Username of the user
    var password: String? = nil // Optional password (not stored in UserDefaults)
    
    // Save the user object to UserDefaults
    static func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    // Retrieve the user object from UserDefaults
    static func getUser() -> User? {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            print("User loaded: \(user)")
            return user
        }
        print("No user found")
        return nil
    }
    
    // Remove the user object from UserDefaults
    static func clearUser() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    // Coding keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case username
    }
} 