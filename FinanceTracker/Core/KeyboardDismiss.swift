import UIKit
import SwiftUI

// MARK: - UIApplication helper

extension UIApplication {
    /// Resigns the first responder, dismissing any active keyboard.
    func endEditing() {
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

// MARK: - View modifiers

extension View {
    /// Adds a "Done" button on the keyboard accessory toolbar so users
    /// can dismiss the keyboard without tapping elsewhere.
    func keyboardDoneToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.endEditing()
                } label: {
                    Text("Done").fontWeight(.semibold)
                }
            }
        }
    }

    /// Dismisses the keyboard when the user taps on any empty background area.
    /// Apply to a ScrollView or the outermost VStack of a screen.
    func dismissKeyboardOnTap() -> some View {
        background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { UIApplication.shared.endEditing() }
        )
    }
}
