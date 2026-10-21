//
//  ApiKeyView.swift
//  Task-XP
//
//  Created by Daiki Hagiwara on 9/16/26.
//

import SwiftUI

enum AllowedModel: String, CaseIterable {
    case gpt5Nano = "gpt-5-nano"
    case luna = "gpt-5.6-luna"
    case terra = "gpt-5.6-terra"
}

struct SelectApiKeyView: View {
    private let keychainManager: KeychainManager
    @AppStorage("defaultApiKeyAccount")
    private var defaultApiKeyAccount: String = ""
    @State private var accounts: [String] = []
    @State private var errorMessage: String?
    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
    }
    
    var body: some View {
        Form {
            Picker(selection: $defaultApiKeyAccount) {
                ForEach(accounts, id: \.self) { account in
                    Text(account)
                        .tag(account)
                }
            } label: {
                Text("API key")
                    .primaryTextStyle()
            } currentValueLabel: {
                Text(accounts.contains(defaultApiKeyAccount)
                     ? defaultApiKeyAccount
                     : "Select API Key"
                )
                .secondaryTextStyle()
            }
            .tint(
                defaultApiKeyAccount.isEmpty
                ? AppColors.textSecondary
                : AppColors.textPrimary
            )
            .appListRowStyle()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Select API Key")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                accounts = try keychainManager.getAllAccounts()
                if !defaultApiKeyAccount.isEmpty &&
                   !accounts.contains(defaultApiKeyAccount) {
                    defaultApiKeyAccount = ""
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .errorAlert(title: "Failed to get API keys", errorMessage: $errorMessage)
        .appBackground()
    }
}

struct SelectApiModelView: View {
    @Environment(\.dismiss) private var dismiss
    private let keychainManager: KeychainManager
    private let openAIApiManager: OpenAIApiManager
    @AppStorage("defaultApiModel")
    private var defaultApiModel: String = ""
    @AppStorage("defaultApiKeyAccount")
    private var defaultApiKeyAccount: String = ""
    @State private var models: [String] = []
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    init(keychainManger: KeychainManager, openAiApiManager: OpenAIApiManager) {
        self.keychainManager = keychainManger
        self.openAIApiManager = openAiApiManager
    }
    
    private func displayName(for model: String) -> String {
        switch model {
        case "gpt-5-nano":
            return "GPT-5 Nano (Lowest cost)"
        case "gpt-5.6-luna":
            return "GPT-5.6 Luna (Recommended)"
        case "gpt-5.6-terra":
            return "GPT-5.6 Terra (Higher quality)"
        default:
            return model
        }
    }
    
    var body: some View {
        Form {
            if isLoading {
                HStack {
                    Text("Model")
                        .primaryTextStyle()
                    Spacer()
                    ProgressView()
                        .tint(AppColors.textSecondary.opacity(0.3))
                        .padding(.horizontal, 5)
                }
                .listRowBackground(AppColors.card)
            } else {
                Picker(selection: $defaultApiModel) {
                    ForEach(models, id: \.self) { model in
                        Text(displayName(for: model))
                            .tag(model)
                    }
                } label: {
                    Text("Model")
                        .primaryTextStyle()
                } currentValueLabel: {
                    Text(models.contains(defaultApiModel)
                         ? displayName(for: defaultApiModel)
                         : "Select API Model"
                    )
                    .primaryTextStyle()
                }
                .tint(
                    defaultApiModel.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textPrimary
                )
                .appListRowStyle()
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Select API Key")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                isLoading = true
                defer {
                    isLoading = false
                }
                let apiKey = try keychainManager.get(account: defaultApiKeyAccount)
                let aiModels = try await openAIApiManager.getModels(apiKey: apiKey)
                models = aiModels.compactMap { model in
                    let id = model.id.lowercased()
                    
                    return AllowedModel(rawValue: id)?.rawValue
                }
                if defaultApiModel.isEmpty {
                    if models.contains(AllowedModel.luna.rawValue) {
                        defaultApiModel = AllowedModel.luna.rawValue
                    } else {
                        defaultApiModel = models.first ?? ""
                    }
                } else if !models.contains(defaultApiModel) {
                    defaultApiModel = ""
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .errorAlert(title: "Failed to get API keys", errorMessage: $errorMessage)
        .appBackground()
    }
}

struct AddApiKeyView: View {
    private let keychainManager: KeychainManager
    private let openAIApiManager: OpenAIApiManager
    @AppStorage("defaultApiKeyAccount")
    private var defaultApiKeyAccount: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var apiKeyNameField: String = ""
    @State private var apiKeyField: String = ""
    @State private var showDiscardDialog: Bool = false
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    init(keychainManager: KeychainManager, openAIApiManager: OpenAIApiManager) {
        self.keychainManager = keychainManager
        self.openAIApiManager = openAIApiManager
    }
    
    private var isSaveButtonDisabled: Bool {
        apiKeyNameField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        apiKeyField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var hasUnsavedChanges: Bool {
        !apiKeyNameField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !apiKeyField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(){
                Form {
                    Section {
                        HStack {
                            Text("Name")
                                .primaryTextStyle()

                            TextField(
                                "Name",
                                text: $apiKeyNameField,
                                prompt: Text("e.g. Personal")
                                    .appInputPromptStyle()
                            )
                            .primaryTextStyle()
                            .textContentType(.oneTimeCode)
                        }
                        .appListRowStyle()
                        HStack {
                            Text("API Key")
                                .primaryTextStyle()
                            SecureField(
                                "API Key",
                                text: $apiKeyField,
                                prompt: Text("Enter your API key")
                                    .foregroundStyle(AppColors.textSecondary)
                            )
                            .primaryTextStyle()
                            .textContentType(.oneTimeCode)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        }
                        .appListRowStyle()
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if hasUnsavedChanges {
                            showDiscardDialog = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                    .appButtonImageStyle()
                    .confirmationDialog("Discard?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
                        Button(role: .destructive) {
                            dismiss()
                        } label: {
                            Text("Discard")
                        }
                        Button(role: .cancel) {
                            
                        } label: {
                            Text("Cancel")
                        }
                    } message: {
                        Text("Unsaved changes will be lost.")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        _Concurrency.Task {
                            do {
                                isLoading = true
                                defer {
                                    isLoading = false
                                }
                                let account = apiKeyNameField.trimmingCharacters(in: .whitespacesAndNewlines)
                                let key = apiKeyField.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !account.isEmpty else {
                                    throw KeychainValidationError.emptyAccount
                                }
                                guard !key.isEmpty else {
                                    throw KeychainValidationError.emptyValue
                                }
                                guard try await openAIApiManager.isApiKeyValid(apiKey: key) else {
                                    throw OpenAIApiError.invalidApiKey
                                }
                                try keychainManager.add(value: key, account: account)
                                if defaultApiKeyAccount == "" {
                                    defaultApiKeyAccount = account
                                }
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Save", systemImage: "checkmark")
                        }
                    }
                    .appButtonImageStyle()
                    .disabled(isSaveButtonDisabled)
                    .opacity(isSaveButtonDisabled ? 0.5 : 1)
                }
            }
        }
        .interactiveDismissDisabled(hasUnsavedChanges)
        .background {
            UIKitViewController(
                onDismissAttempt: {
                    if hasUnsavedChanges {
                        showDiscardDialog = true
                    }
                }
            )
        }
        .errorAlert(title: "Failed to save API key", errorMessage: $errorMessage)
        .appBackground()
    }
}

struct DeleteApikeyView: View {
    private let keychainManager: KeychainManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultApiKeyAccount")
    private var defaultApiKeyAccount: String = ""
    @State private var errorMessage: String?
    @State private var accounts: [String] = []
    @State private var selectedApiKeyAccount: String = ""
    @State private var showConfirmationDialog: Bool = false
    
    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
    }
    private var isDeleteButtonDisabled: Bool {
        selectedApiKeyAccount.isEmpty
    }
    var body: some View {
        NavigationStack {
            Form {
                Picker(selection: $selectedApiKeyAccount) {
                    ForEach(accounts, id: \.self) { account in
                        Text(account)
                            .tag(account)
                    }
                } label: {
                    Text("API key")
                        .primaryTextStyle()
                } currentValueLabel: {
                    Text(selectedApiKeyAccount.isEmpty ? "Select API Key" : selectedApiKeyAccount)
                        .secondaryTextStyle()
                }
                .tint(
                    selectedApiKeyAccount.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textPrimary
                )
                .appListRowStyle()
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Delete API Key")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                do {
                    accounts = try keychainManager.getAllAccounts()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            .errorAlert(title: "Failed to delete API keys", errorMessage: $errorMessage)
            .navigationTitle("Delete API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showConfirmationDialog = true
                    } label: {
                        Label("Delete", systemImage: "checkmark")
                            .appButtonImageStyle()
                    }
                    .disabled(isDeleteButtonDisabled)
                    .opacity(isDeleteButtonDisabled ? 0.5 : 1)
                    .confirmationDialog("Delete API Key?", isPresented: $showConfirmationDialog) {
                        Button(role: .destructive) {
                            do {
                                try keychainManager.delete(account: selectedApiKeyAccount)
                                if defaultApiKeyAccount == selectedApiKeyAccount {
                                    defaultApiKeyAccount = ""
                                }
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        } label: {
                            Text("Delete")
                        }
                        Button(role: .cancel) {
                            
                        } label: {
                            Text("Cancel")
                        }
                    } message: {
                        Text("\(selectedApiKeyAccount) will be deleted.")
                    }
                }
            }
            .appBackground()
        }
    }
}

struct ApiKeyView: View {
    private let keychainManager = KeychainManager()
    private let openAIApiManager = OpenAIApiManager()
    @State private var showAddApiKeyView: Bool = false
    @State private var showDeleteApiKeyView: Bool = false
    @State private var showAllSettings: Bool = false
    
    private func checkDefaultApiKeyAccount() -> Void {
        let account = UserDefaults.standard.string(forKey: "defaultApiKeyAccount")
        if account != nil {
            showAllSettings = true
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if showAllSettings {
                    NavigationLink {
                        SelectApiKeyView(keychainManager: keychainManager)
                    } label: {
                        Text("Select API Key")
                            .primaryTextStyle()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .appButtonImageStyle()
                    }
                    .appListRowStyle()
                    NavigationLink {
                        SelectApiModelView(keychainManger: keychainManager, openAiApiManager: openAIApiManager)
                    } label: {
                        Text("Select Model")
                            .primaryTextStyle()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .appButtonImageStyle()
                    }
                    .appListRowStyle()
                }
                Button {
                    showAddApiKeyView = true
                } label: {
                    Text("Add API Key")
                        .font(.appBody)
                }
                .appListRowStyle()
                .sheet(
                    isPresented: $showAddApiKeyView,
                    onDismiss: { checkDefaultApiKeyAccount() }
                ) {
                    AddApiKeyView(keychainManager: keychainManager, openAIApiManager: openAIApiManager)
                }
                if showAllSettings {
                    Button {
                        showDeleteApiKeyView = true
                    } label: {
                        Text("Delete API Key")
                            .font(.appBody)
                    }
                    .listRowBackground(AppColors.card)
                    .listRowSeparatorTint(AppColors.separator)
                    .sheet(
                        isPresented: $showDeleteApiKeyView,
                        onDismiss: { checkDefaultApiKeyAccount() }
                    ) {
                        DeleteApikeyView(keychainManager: keychainManager)
                    }
                }
            }
            .navigationTitle("OpenAI API")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .navigationLinkIndicatorVisibility(.hidden)
            .appBackground()
            .onAppear {
                checkDefaultApiKeyAccount()
            }
        }
    }
}

#Preview {
    ApiKeyView()
}
