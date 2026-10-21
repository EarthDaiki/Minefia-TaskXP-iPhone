//
//  UIKitViewController.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 9/13/26.
//

import SwiftUI
import UIKit

struct UIKitViewController: UIViewControllerRepresentable {
    let onDismissAttempt: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismissAttempt: onDismissAttempt)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.onDismissAttempt = onDismissAttempt
        DispatchQueue.main.async {
            uiViewController.parent?.presentationController?.delegate = context.coordinator
        }
    }
    
    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var onDismissAttempt: () -> Void
        
        init(onDismissAttempt: @escaping () -> Void) {
            self.onDismissAttempt = onDismissAttempt
        }
        
        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            onDismissAttempt()
        }
    }
}
