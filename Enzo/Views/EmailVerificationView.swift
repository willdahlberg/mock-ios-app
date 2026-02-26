//
//  EmailVerificationView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-03-12.
//

import SwiftUI
import Combine

struct EmailVerificationView: View {
    let email: String
    @Environment(\.dismiss) private var dismiss
    @State private var verificationCode = Array(repeating: "", count: 6)
    @State private var currentField = 0
    @State private var isLoading = false
    @State private var error: String?
    @FocusState private var focusedField: Int?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Email Verification")
                .font(.largeTitle)
                .bold()
            
            Text("Enter the 6-digit code sent to")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(email)
                .font(.subheadline)
                .bold()
            
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    VerificationDigitField(
                        text: $verificationCode[index],
                        isFocused: focusedField == index
                    )
                    .focused($focusedField, equals: index)
                    .onChange(of: verificationCode[index]) { newValue in
                        if newValue.count >= 1 {
                            verificationCode[index] = String(newValue.suffix(1))
                            if index < 5 {
                                currentField = index + 1
                                focusedField = currentField
                            } else {
                                focusedField = nil
                                verifyCode()
                            }
                        } else if newValue.isEmpty && index > 0 {
                            currentField = index - 1
                            focusedField = currentField
                        }
                    }
                }
            }
            .padding(.vertical, 20)
            
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
            }
            
            if isLoading {
                ProgressView()
                    .padding()
            }
            
            Button("Cancel") {
                dismiss()
            }
            .padding()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = 0
            }
        }
    }
    
    private func verifyCode() {
        let code = verificationCode.joined()
        guard code.count == 6 else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await AuthenticationManager.shared.verifyEmailCode(email: email, code: code)
                isLoading = false
                dismiss()
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = "Invalid verification code. Please try again."
                    verificationCode = Array(repeating: "", count: 6)
                    currentField = 0
                    focusedField = 0
                }
            }
        }
    }
}

struct VerificationDigitField: View {
    @Binding var text: String
    var isFocused: Bool
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: 50, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.accentColor : Color.gray, lineWidth: 2)
                    .background(Color(.systemGray6).cornerRadius(8))
            )
            .font(.title2.bold())
    }
}

#Preview {
    EmailVerificationView(email: "user@example.com")
}
