// T2
//  LoginView.swift

import SwiftUI
import AuthenticationServices

// Login View - Handles user authentication and provides access to the registration view
struct LoginView: View {
    // Environment and state objects
    @EnvironmentObject private var appState: AppState // App state for managing user session
    @StateObject private var userService = UserService() // Service for handling user-related operations
    @State private var username = "" // Username input field
    @State private var password = "" // Password input field
    @State private var showingAlert = false // Controls alert visibility
    @State private var alertMessage = "" // Message to display in alert
    @State private var showingRegistration = false // Controls registration view visibility
    @State private var isSecured = true // Controls password field security
    @State private var isLoading = false // Loading state indicator
    @State private var showSuccessAlert = false // Controls success alert visibility
    
    var body: some View {
        ZStack {
            // Background gradient for visual appeal
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and title section
                    VStack(spacing: 20) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 50)
                        
                        Text("Health Monitoring System")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Sign in to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Login form section
                    VStack(spacing: 20) {
                        // Username input field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("", text: $username)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .disabled(isLoading)
                        }
                        
                        // Password input field with toggle visibility
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                if isSecured {
                                    SecureField("", text: $password)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .textContentType(.password)
                                        .disabled(isLoading)
                                } else {
                                    TextField("", text: $password)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .textContentType(.password)
                                        .disabled(isLoading)
                                }
                                
                                Button(action: { isSecured.toggle() }) {
                                    Image(systemName: isSecured ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Sign in button with loading indicator
                        Button(action: login) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        .disabled(isLoading)
                        
                        // Registration link
                        Button(action: { showingRegistration = true }) {
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundColor(.secondary)
                                Text("Sign Up")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 30)
            }
        }
        // Error alert
        .alert("Notice", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        // Success alert
        .alert("Login Successful", isPresented: $showSuccessAlert) {
            Button("OK") {
                appState.isLoggedIn = true
            }
        } message: {
            Text("Welcome back!")
        }
        // Navigation to registration view
        .navigationDestination(isPresented: $showingRegistration) {
            RegisterView()
        }
    }
    
    // Handles login process
    private func login() {
        // Validate input fields
        if username.isEmpty || password.isEmpty {
            alertMessage = "Please enter username and password"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        // Perform login asynchronously
        Task {
            do {
                let user = try await userService.login(username: username, password: password)
                User.saveUser(user)
                appState.currentUser = user
                showSuccessAlert = true
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
            isLoading = false
        }
    }
}

// Custom text field style for consistent appearance
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AppState())
    }
} 