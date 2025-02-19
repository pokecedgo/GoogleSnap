//
//  RegistrationView.swift
//  GoogleSnap
//
//  Created by Cedric Petilos on 1/3/25.
//
import SwiftUI
import FirebaseAuth

struct RegistrationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var navigateToLogin = false

    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Register")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }

                if isLoading {
                    ProgressView()
                } else {
                    Button(action: {
                        registerUser()
                    }) {
                        Text("Register")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }

                Button(action: {
                    navigateToLogin = true
                }) {
                    Text("Already have an account? Log in")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .padding(.top)

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
            }
        }
    }

    func registerUser() {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "All fields are required."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        errorMessage = ""

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            isLoading = false

            if let error = error {
                errorMessage = error.localizedDescription
                return
            }

            if let user = authResult?.user {
                dataManager.createUserInDatabase(userId: user.uid, email: email)
                dataManager.checkAuthState()
            }
        }
    }
}

#Preview {
    RegistrationView()
}
