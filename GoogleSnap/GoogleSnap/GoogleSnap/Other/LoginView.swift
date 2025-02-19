//
//  LoginView.swift
//  GoogleSnap
//
//  Created by Cedric Petilos on 1/4/25.
//
import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Log In")
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

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
            }

            if isLoading {
                ProgressView()
            } else {
                Button(action: {
                    loginUser()
                }) {
                    Text("Log In")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }

            Button(action: {
                dismiss() // Dismiss the login view
            }) {
                Text("Don't have an account? Register")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            .padding(.top)

            Spacer()
        }
        .padding()
    }

    func loginUser() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            return
        }

        isLoading = true
        errorMessage = ""

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            isLoading = false

            if let error = error {
                errorMessage = error.localizedDescription
                return
            }

            dataManager.checkAuthState()
        }
    }
}


#Preview {
    LoginView()
}
