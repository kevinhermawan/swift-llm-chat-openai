//
//  AppView.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI

struct AppView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var isSettingsPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("OpenAI") {
                        NavigationLink("Chat Completion") {
                            ChatCompletionView()
                                .onAppear {
                                    viewModel.isUsingCustomApi = false
                                }
                        }
                        
                        NavigationLink("Multimodal") {
                            MultimodalView()
                                .onAppear {
                                    viewModel.isUsingCustomApi = false
                                }
                        }
                        
                        NavigationLink("Tool Calling") {
                            ToolCallingView()
                                .onAppear {
                                    viewModel.isUsingCustomApi = false
                                }
                        }
                        
                        NavigationLink("Response Format") {
                            ResponseFormatView()
                                .onAppear {
                                    viewModel.isUsingCustomApi = false
                                }
                        }
                    }
                    .disabled(viewModel.openaiApiKey.isEmpty)
                    
                    Section("OpenAI-Compatible") {
                        NavigationLink("Chat Completion") {
                            ChatCompletionView()
                                .onAppear {
                                    viewModel.isUsingCustomApi = true
                                }
                        }
                        
                        NavigationLink("Tool Calling") {
                            ToolCallingView()
                                .onAppear {
                                    viewModel.isUsingCustomApi = true
                                }
                        }
                    }
                    .disabled(viewModel.customApiKey.isEmpty)
                    .disabled(viewModel.customChatEndpoint.isEmpty)
                    .disabled(viewModel.customModelEndpoint.isEmpty)
                }
            }
            .navigationTitle("OpenAI Playground")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        isSettingsPresented = true
                    }
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
        }
    }
}
