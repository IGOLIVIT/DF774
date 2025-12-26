//
//  DF774App.swift
//  DF774
//
//  Created by IGOR on 14/12/2025.
//

import SwiftUI

@main
struct DF774App: App {
    
    // Инициализируем сервис уведомлений
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Инициализируем OneSignal при запуске приложения
                    notificationService.initialize()
                }
        }
    }
}
