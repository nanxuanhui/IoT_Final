//T2
//AuthService.swift

import SwiftUI
import AuthenticationServices

// Authentication service for handling Apple Sign In and user session
class AuthService: NSObject, ObservableObject {
    @Published var isAuthenticated = false // Indicates if the user is authenticated
    @Published var currentUser: User?      // The currently logged-in user
    
    // Sign in with Apple
    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider() // Apple ID provider
        let request = provider.createRequest()          // Create authorization request
        request.requestedScopes = [.fullName, .email]   // Request full name and email
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request]) // Controller for Apple sign in
        authorizationController.delegate = self         // Set delegate
        authorizationController.performRequests()       // Start the authorization flow
    }
    
    // Sign out the current user
    func signOut() {
        User.clearUser()       // Remove user from UserDefaults
        currentUser = nil      // Clear current user
        isAuthenticated = false // Set authentication state to false
    }
}

// Apple Sign In delegate methods
extension AuthService: ASAuthorizationControllerDelegate {
    // Called when Apple Sign In completes successfully
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let user = User(
                username: appleIDCredential.fullName?.givenName ?? "", // Use given name as username
                password: "" // No password needed for Apple Sign In
            )
            
            User.saveUser(user)    // Save user to UserDefaults
            currentUser = user     // Set current user
            isAuthenticated = true // Set authentication state to true
        }
    }
    
    // Called when Apple Sign In fails
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In error: \(error.localizedDescription)")
    }
} 