//
//  ViewExtension.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 10/4/26.
//

import SwiftUI

extension View {
    func errorAlert(title: String = "Error", errorMessage: Binding<String?>, onDismiss: (() -> Void)? = nil) -> some View {
        self.alert(
            title,
            isPresented: Binding(
                get: {
                    errorMessage.wrappedValue != nil
                },
                set: { isPresented in
                    if !isPresented {
                        errorMessage.wrappedValue = nil
                        onDismiss?()
                    }
                }
            )
        ) {
            Button(role: .cancel) {
                
            } label: {
                Text("OK")
            }
        } message: {
            Text(errorMessage.wrappedValue ?? "")
        }
    }
    
    func confirmationAlert(title: String, isPresented: Binding<Bool>, message: String, onContinue: (() -> Void)? = nil, onClose: (() -> Void)? = nil) -> some View {
        self.alert(
            title,
            isPresented: isPresented
        ) {
            Button(role: .none) {
                onContinue?()
            } label: {
                Text("Keep Adding")
            }
            Button(role: .close) {
                onClose?()
            } label: {
                Text("Finish Adding")
            }
        } message: {
            Text(message)
        }
    }
    
    func deleteConfirmationAlert(title: String, isPresented: Binding<Bool>, message: String, onDelete: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) -> some View {
        self.alert(
            title,
            isPresented: isPresented
        ) {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Text("Continue")
            }
            Button(role: .cancel) {
                onCancel?()
            } label: {
                Text("Cancel")
            }
        } message: {
            Text(message)
        }
    }
}
