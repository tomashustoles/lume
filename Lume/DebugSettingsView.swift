//
//  DebugSettingsView.swift
//  Lume
//
//  Temporary debug view to test splash screen
//

import SwiftUI

struct DebugSettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Onboarding") {
                    Toggle("Has Completed Onboarding", isOn: $hasCompletedOnboarding)
                    
                    Button("Reset Onboarding (See Splash Again)") {
                        hasCompletedOnboarding = false
                        // App will automatically show splash screen
                    }
                    .foregroundColor(.red)
                }
                
                Section("Info") {
                    Text("Current Status: \(hasCompletedOnboarding ? "Completed" : "Not Completed")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Close and reopen the app to see the splash screen after resetting.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Debug Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DebugSettingsView()
}
