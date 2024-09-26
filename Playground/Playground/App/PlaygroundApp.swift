//
//  PlaygroundApp.swift
//  Playground
//
//  Created by Kevin Hermawan on 9/27/24.
//

import SwiftUI

@main
struct PlaygroundApp: App {
    @State private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appViewModel)
        }
    }
}
