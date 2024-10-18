//
//  AppView.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI

struct AppView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var isPreferencesPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    ForEach(ServiceProvider.allCases, id: \.rawValue) { provider in
                        Section(provider.rawValue) {
                            NavigationLink("Chat") {
                                ChatView(provider: provider)
                            }
                            
                            NavigationLink("Vision") {
                                VisionView(provider: provider)
                            }
                            
                            NavigationLink("Tool Use") {
                                ToolUseView(provider: provider)
                            }
                            
                            if provider == .openai {
                                NavigationLink("Response Format") {
                                    ResponseFormatView(provider: provider)
                                }
                            }
                            
                            if provider == .openRouter {
                                NavigationLink("Fallback Model") {
                                    FallbackModelView(provider: provider)
                                }
                            }
                        }
                        .disabled(provider == .openai && viewModel.openaiAPIKey.isEmpty)
                        .disabled(provider == .openRouter && viewModel.openRouterAPIKey.isEmpty)
                        .disabled(provider == .groq && viewModel.groqAPIKey.isEmpty)
                    }
                }
            }
            .navigationTitle("OpenAI Playground")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Preferences", systemImage: "gearshape", action: { isPreferencesPresented.toggle() })
                }
            }
            .sheet(isPresented: $isPreferencesPresented) {
                PreferencesView()
            }
        }
    }
}
