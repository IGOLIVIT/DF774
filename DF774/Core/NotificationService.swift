//
//  NotificationService.swift
//  DF774
//
//  Created by IGOR on 18/12/2025.
//

import SwiftUI
import OneSignalFramework
import UserNotifications
import Combine

// MARK: - Сервис для работы с push уведомлениями
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published private(set) var isInitialized = false
    @Published private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var playerId: String?
    
    // Обработчики для OneSignal
    private let clickHandler = NotificationClickHandler()
    
    private init() {}
    
    /// Инициализация OneSignal
    func initialize() {
        guard !isInitialized else { return }
        
        let appId = DataManager().ONESIGNAL_APP_ID
        guard !appId.isEmpty && appId != "YOUR_ONESIGNAL_APP_ID" else {
            print("❌ OneSignal App ID не настроен в DataManager")
            return
        }
        
        print("🔔 Инициализация OneSignal с App ID: \(appId)")
        
        // Инициализируем OneSignal
        OneSignal.initialize(appId, withLaunchOptions: nil)
        
        // Запрашиваем разрешение на уведомления
        OneSignal.Notifications.requestPermission { accepted in
            Task { @MainActor in
                print("🔔 Разрешение на уведомления: \(accepted ? "Получено" : "Отклонено")")
                self.updatePermissionStatus()
            }
        }
        
        // Устанавливаем обработчики
        setupNotificationHandlers()
        
        isInitialized = true
        print("✅ OneSignal успешно инициализирован")
    }
    
    /// Настройка обработчиков уведомлений
    private func setupNotificationHandlers() {
        // Обработчик клика по уведомлению
        OneSignal.Notifications.addClickListener(clickHandler)
        
        // Получаем Player ID через другой способ
        Task {
            // Ждем немного для инициализации
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
            
            await MainActor.run {
                // Пытаемся получить Player ID
                if let userId = OneSignal.User.onesignalId {
                    self.playerId = userId
                    print("🔔 OneSignal Player ID: \(userId)")
                } else {
                    print("🔔 OneSignal Player ID еще не готов")
                }
            }
        }
    }
    
    /// Обновление статуса разрешений
    func updatePermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionStatus = settings.authorizationStatus
                print("🔔 Статус разрешений: \(settings.authorizationStatus.description)")
            }
        }
    }
    
    /// Запрос разрешений на уведомления
    func requestPermission() {
        OneSignal.Notifications.requestPermission { accepted in
            Task { @MainActor in
                print("🔔 Повторный запрос разрешений: \(accepted ? "Получено" : "Отклонено")")
                self.updatePermissionStatus()
            }
        }
    }
    
    /// Установка внешнего User ID (например, ID пользователя из вашей системы)
    func setExternalUserId(_ userId: String) {
        OneSignal.login(userId)
        print("🔔 Установлен External User ID: \(userId)")
    }
    
    /// Добавление тега
    func addTag(key: String, value: String) {
        OneSignal.User.addTag(key: key, value: value)
        print("🔔 Добавлен тег: \(key) = \(value)")
    }
    
    /// Удаление тега
    func removeTag(key: String) {
        OneSignal.User.removeTag(key)
        print("🔔 Удален тег: \(key)")
    }
    
    /// Отправка события (для аналитики)
    func sendEvent(name: String, properties: [String: Any] = [:]) {
        OneSignal.Session.addOutcome(name)
        print("🔔 Отправлено событие: \(name)")
    }
    
    /// Установка тегов для веб-режима
    func setupWebModeTags(url: String) {
        addTag(key: "app_mode", value: "grey")
        addTag(key: "web_url", value: url)
        addTag(key: "platform", value: "ios")
        print("🔔 Установлены теги для веб-режима")
    }
    
    /// Установка тегов для нативного режима
    func setupNativeModeTags() {
        addTag(key: "app_mode", value: "white")
        removeTag(key: "web_url")
        addTag(key: "platform", value: "ios")
        print("🔔 Установлены теги для нативного режима")
    }
    
    /// Получение текущего Player ID
    var currentPlayerId: String? {
        return playerId
    }
}

// MARK: - Обработчики OneSignal

/// Обработчик кликов по уведомлениям
class NotificationClickHandler: NSObject, OSNotificationClickListener {
    func onClick(event: OSNotificationClickEvent) {
        print("🔔 Клик по уведомлению:")
        print("Action ID: \(event.result.actionId ?? "нет")")
        print("URL: \(event.result.url ?? "нет")")
        
        // Логируем весь результат для отладки
        print("Click Result: \(event.result)")
        
        // Здесь можно добавить логику обработки клика
        // Например, открытие определенного экрана или URL
    }
}

// MARK: - Расширение для описания статуса разрешений
extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Не определен"
        case .denied: return "Отклонен"
        case .authorized: return "Разрешен"
        case .provisional: return "Временный"
        case .ephemeral: return "Эфемерный"
        @unknown default: return "Неизвестный"
        }
    }
}
