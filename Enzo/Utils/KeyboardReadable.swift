//
//  KeyboardReadable.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-31.
//

import SwiftUI
import UIKit

struct KeyboardWillShowModifier: ViewModifier {
  let action: (CGFloat) -> Void
  
  func body(content: Content) -> some View {
    content
      .onAppear {
        NotificationCenter.default.addObserver(
          forName: UIResponder.keyboardWillShowNotification,
          object: nil,
          queue: .main
        ) { notification in
          guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
          }
          action(keyboardFrame.height)
        }
      }
  }
}

struct KeyboardDidShowModifier: ViewModifier {
  let action: (CGFloat) -> Void
  
  func body(content: Content) -> some View {
    content
      .onAppear {
        NotificationCenter.default.addObserver(
          forName: UIResponder.keyboardDidShowNotification,
          object: nil,
          queue: .main
        ) { notification in
          guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
          }
          action(keyboardFrame.height)
        }
      }
  }
}

extension View {
  func onKeyboardWillShow(_ action: @escaping (CGFloat) -> Void) -> some View {
    modifier(KeyboardWillShowModifier(action: action))
  }
  
  func onKeyboardDidShow(_ action: @escaping (CGFloat) -> Void) -> some View {
    modifier(KeyboardDidShowModifier(action: action))
  }
}
