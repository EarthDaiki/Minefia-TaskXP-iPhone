//
//  AddTaskAiView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 9/20/26.
//

import SwiftUI

struct AddTaskAiView: View {
    @Binding private var prompt: String
    private let openAIApiManager = OpenAIApiManager()
    private let keychainManager = KeychainManager()
    private let onGenerated: (GeneratedTask) -> Void
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    @AppStorage("defaultApiModel")
    private var defaultApiModel: String = ""
    
    init(
        prompt: Binding<String>,
        onGenerated: @escaping (GeneratedTask) -> Void
    ) {
        self._prompt = prompt
        self.onGenerated = onGenerated
    }
    
    private var hasPrompt: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var defaultApiKeyAccount: String {
        UserDefaults.standard.string(
            forKey: "defaultApiKeyAccount"
        ) ?? ""
    }
    
    var body: some View {
        VStack(spacing: 20){
            Text("Create a new task with AI")
                .titleTextStyle()
            
            TextField(
                "Prompt",
                text: $prompt,
                prompt: Text("Create a new task")
                    .appInputPromptStyle(),
                axis: .vertical
            )
            .font(.body)
            .lineLimit(4...8)
            .appInputCard()
            
            Button {
                _Concurrency.Task {
                    isLoading = true
                    defer {
                        isLoading = false
                    }
                    let userInput = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    do {
                        let apiKey = try keychainManager.get(account: defaultApiKeyAccount)
                        if defaultApiModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let aiModels = try await openAIApiManager.getModels(apiKey: apiKey)
                            let models = aiModels.compactMap { model in
                                let id = model.id.lowercased()
                                
                                return AllowedModel(rawValue: id)?.rawValue
                            }
                            if models.contains(AllowedModel.luna.rawValue) {
                                defaultApiModel = AllowedModel.luna.rawValue
                            } else {
                                defaultApiModel = models.first ?? ""
                            }
                        }
                        let generatedTask = try await openAIApiManager.createTask(apiKey: apiKey, model: defaultApiModel, userInput: userInput)
                        onGenerated(generatedTask)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .padding()
                        .primaryTextStyle()
                } else {
                    Text("Generate task")
                        .padding()
                        .primaryTextStyle()
                }
            }
            .background(
                AppColors.primary,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .disabled(!hasPrompt)
            .opacity(!hasPrompt ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .errorAlert(title: "Task AI Error", errorMessage: $errorMessage)
        .appBackground()
    }
}

#Preview {
    @Previewable @State var prompt: String = ""
    AddTaskAiView(prompt: $prompt, onGenerated: { _ in })
}
