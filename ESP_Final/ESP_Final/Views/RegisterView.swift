// T2
//  RegisterView.swift

import SwiftUI

// Registration View - Handles user account creation
struct RegisterView: View {
    // MARK: - Environment and State Objects
    
    /// Environment value for dismissing the view
    @Environment(\.dismiss) private var dismiss
    
    /// App state for managing user session
    @EnvironmentObject private var appState: AppState
    
    /// Service for handling user-related operations
    @StateObject private var userService = UserService()
    
    // MARK: - State Properties
    
    /// Username input field
    @State private var username = ""
    
    /// Password input field
    @State private var password = ""
    
    /// Password confirmation field
    @State private var confirmPassword = ""
    
    /// Controls alert visibility
    @State private var showingAlert = false
    
    /// Message to display in alert
    @State private var alertMessage = ""
    
    /// Controls password field security
    @State private var isSecured = true
    
    /// Controls confirm password field security
    @State private var isConfirmSecured = true
    
    /// Loading state indicator
    @State private var isLoading = false
    
    /// Controls success alert visibility
    @State private var showSuccessAlert = false
    
    // MARK: - Body
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
                    // Title section
                    VStack(spacing: 10) {
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Please fill in the following information to complete registration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    
                    // Registration form section
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
                        
                        // Password input field with visibility toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                if isSecured {
                                    SecureField("", text: $password)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .textContentType(.newPassword)
                                        .disabled(isLoading)
                                } else {
                                    TextField("", text: $password)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .textContentType(.newPassword)
                                        .disabled(isLoading)
                                }
                                
                                Button(action: { isSecured.toggle() }) {
                                    Image(systemName: isSecured ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Confirm password field with visibility toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                if isConfirmSecured {
                                    SecureField("", text: $confirmPassword)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .textContentType(.newPassword)
                                        .disabled(isLoading)
                                } else {
                                    TextField("", text: $confirmPassword)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .textContentType(.newPassword)
                                        .disabled(isLoading)
                                }
                                
                                Button(action: { isConfirmSecured.toggle() }) {
                                    Image(systemName: isConfirmSecured ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Register button with loading indicator
                        Button(action: register) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Register")
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
                        
                        // Back to login button
                        Button(action: { dismiss() }) {
                            HStack {
                                Text("Already have an account?")
                                    .foregroundColor(.secondary)
                                Text("Back to Login")
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
        .alert("Registration Successful", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your account has been successfully registered! Please log in.")
        }
    }
    
    // MARK: - Methods
    
    /// Handles the registration process
    private func register() {
        print("Register button tapped")
        // Validate input fields
        if username.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            alertMessage = "Please fill in all fields"
            showingAlert = true
            print("Some fields are empty")
            return
        }
        
        // Validate password match
        if password != confirmPassword {
            alertMessage = "Passwords do not match"
            showingAlert = true
            print("Passwords do not match")
            return
        }
        
        isLoading = true
        
        // Perform registration asynchronously
        Task {
            do {
                let user = try await userService.register(username: username, password: password)
                User.saveUser(user)
                appState.currentUser = user
                showSuccessAlert = true
                print("Register success")
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
                print("Register failed: \(error)")
            }
            isLoading = false
            print("Register finished")
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AppState())
    }
} 