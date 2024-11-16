//
//  Login.swift
//  KBTU Go
//
//  Created by Райымбек Омаров on 16.11.2024.
//

import Foundation
import CryptoKit
import SwiftUI

func getFixedNonce() -> Data {
    // Use a fixed nonce or store the same nonce across registration and login
    // For example, you could use a static 12-byte nonce.
    return Data(repeating: 0, count: 12) // Fixed nonce (unsafe for production but useful for testing)
}


func saveJWTToKeychain(token: String) -> Bool {
    let tokenData = token.data(using: .utf8)!
    
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "userJWT",  // Unique identifier for JWT
        kSecValueData as String: tokenData
    ]
    
    let status = SecItemAdd(query as CFDictionary, nil)
    
    if status == errSecSuccess {
        return true
    } else if status == errSecDuplicateItem {
        // Update if the item already exists
        let attributesToUpdate: [String: Any] = [kSecValueData as String: tokenData]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        return updateStatus == errSecSuccess
    }
    return false
}

func getJWTFromKeychain() -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "userJWT",  // Same identifier
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    if status == errSecSuccess, let data = result as? Data {
        return String(data: data, encoding: .utf8)
    }
    return nil
}
struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var jwt: String? = nil
    var onLoginSuccess: () -> Void
    func encryptPassword(_ password: String, using key: SymmetricKey) -> String? {
        let passwordData = Data(password.utf8)
        
        // Let's assume you are fetching the nonce from somewhere
        let nonceData = getFixedNonce() // Use the fixed nonce data
        
        do {
            // Try to convert nonceData to AES.GCM.Nonce
            let nonce = try AES.GCM.Nonce(data: nonceData)
            
            // Now encrypt the password using the nonce
            let sealedBox = try AES.GCM.seal(passwordData, using: key, nonce: nonce)
            
            return sealedBox.combined?.base64EncodedString()
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    // Send login request with encrypted password
    func sendLoginRequest(email: String, password: String) {
        let url = URL(string: "https://1060-95-59-45-33.ngrok-free.app/api/login")!  // Assuming it's /api/login

        guard let key = getKeyFromKeychain(keyIdentifier: "userSymmetricKey") else {
            message = "Error: Key not found"
            return
        }
        // Encrypt the password with the retrieved key
        guard let encryptedPassword = encryptPassword(password, using: key) else {
            message = "Encryption failed"
            return
        }

        let body: [String: Any] = [
            "email": email,
            "password": encryptedPassword
        ]
        
        // Log the JSON body to see what is being sent
        if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Login JSON: \(jsonString)")  // Here we print the JSON
            }
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            message = "Error: Unable to convert body to JSON"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    message = "Error: \(error.localizedDescription)"
                    return
                }
                
                if let data = data {
                    do {
                        // Attempt to parse the response data
                        let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        
                        if let token = responseObject?["token"] as? String {
                            if saveJWTToKeychain(token: token) {
                                message = "Login successful! JWT saved securely."
                                jwt = token // Update state with the JWT
                                onLoginSuccess()
                            } else {
                                message = "Login successful, but failed to save JWT."
                            }
                        } else {
                            message = "Login failed: Invalid credentials. Token not found."
                        }
                    } catch {
                        message = "Error: Unable to parse server response. Error details: \(error.localizedDescription)"
                    }
                } else {
                    message = "Error: No data received from the server."
                }
            }
        }
        
        task.resume()
    }

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                sendLoginRequest(email: email, password: password)
            }) {
                Text("Login")
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Text(message)
                .padding()
                .foregroundColor(.green)
        }
        .padding()
    }
}
//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView(onLoginSuccess: )
//    }
//}
