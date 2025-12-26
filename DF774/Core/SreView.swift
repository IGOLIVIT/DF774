//
//  SreView.swift
//  DF774
//
//  Created by IGOR on 16/12/2025.
//

import SwiftUI
import Network
import UIKit
import Combine

// MARK: - Режим приложения
enum AppMode: Equatable {
    case white
    case grey(url: String)

    var storedValue: String {
        switch self {
        case .white: return "white"
        case .grey:  return "grey"
        }
    }

    static func loadFromStorage() -> AppMode? {
        let defaults = UserDefaults.standard
        guard let raw = defaults.string(forKey: DataManager().APP_MODE_KEY) else { return nil }
        switch raw {
        case "white":
            return .white
        case "grey":
            if let url = defaults.string(forKey: DataManager().SAVED_URL_KEY), !url.isEmpty {
                return .grey(url: url)
            } else {
                return .white
            }
        default:
            return nil
        }
    }

    func persist() {
        let defaults = UserDefaults.standard
        switch self {
        case .white:
            defaults.setValue("white", forKey: DataManager().APP_MODE_KEY)
            defaults.removeObject(forKey: DataManager().SAVED_URL_KEY)
        case .grey(let url):
            defaults.setValue("grey", forKey: DataManager().APP_MODE_KEY)
            defaults.setValue(url, forKey: DataManager().SAVED_URL_KEY)
        }
    }
}

// MARK: - Монитор сети
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    @Published private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor.queue")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}

// MARK: - Сбор параметров устройства для query
enum DeviceParams {
    static func modelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(String(UnicodeScalar(UInt8(value))))
        }
        return identifier // пример: "iPhone13,2"
    }

    static func osVersion() -> String {
        UIDevice.current.systemVersion // пример: "17.6.1"
    }

    /// Формат lang: "en_US"
    static func languageUNDRegion() -> (lang: String, region: String) {
        let preferred = Locale.preferredLanguages.first ?? "en-US" // например "ru-RU"
        let parts = preferred.split(separator: "-")
        let langCode = parts.first.map(String.init) ?? "en"
        let regionCode = Locale.current.regionCode ?? (parts.count > 1 ? String(parts[1]) : "US")
        let lang = "\(langCode)_\(regionCode)"
        return (lang, regionCode)
    }

    static func uuid() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? ""
    }

    /// Собирает URL с query: model_id, os, lang, rg, uuid
    static func buildTrackedURL(from base: String) throws -> URL {
        guard var comps = URLComponents(string: base) else { throw APIError.badURL }

        // Сохраняем существующие query (если они есть) + добавляем новые
        var items = comps.queryItems ?? []

        let model = modelIdentifier()
        let os = osVersion()
        let (lang, region) = languageUNDRegion()
        let uuid = uuid()

        items.append(URLQueryItem(name: "model_id", value: model))
        items.append(URLQueryItem(name: "os",       value: os))
        items.append(URLQueryItem(name: "lang",     value: lang))
        items.append(URLQueryItem(name: "rg",       value: region))
        items.append(URLQueryItem(name: "uuid",     value: uuid))

        comps.queryItems = items
        guard let url = comps.url else { throw APIError.badURL }
        return url
    }
}

// MARK: - API
enum APIError: Error {
    case badURL
    case badResponse
    case noURLInPayload
}

struct APIClient {
    /// Ожидаем JSON с ключом "url" (String) или сложную структуру с applinks.
    /// К серверу уходит запрос на endpoint + query-параметры устройства.
    static func fetchLandingURL(from endpoint: String) async throws -> String {
        let trackedURL = try DeviceParams.buildTrackedURL(from: endpoint)

        var req = URLRequest(url: trackedURL)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        // Логируем запрос
        print("🌐 SERVER REQUEST:")
        print("URL: \(trackedURL.absoluteString)")
        print("Method: \(req.httpMethod ?? "GET")")
        print("Headers: \(req.allHTTPHeaderFields ?? [:])")
        print("---")

        let (data, resp) = try await URLSession.shared.data(for: req)
        
        // Логируем ответ
        print("📥 SERVER RESPONSE:")
        if let http = resp as? HTTPURLResponse {
            print("Status Code: \(http.statusCode)")
            print("Headers: \(http.allHeaderFields)")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Body: \(responseString)")
        } else {
            print("Response Body: [Unable to decode as UTF-8]")
        }
        print("---")
        
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            print("❌ Bad response status code: \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
            throw APIError.badResponse
        }

        // Парсим JSON и извлекаем "url"
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        if let dict = obj as? [String: Any] {
            print("📋 PARSED JSON: \(dict)")
            
            // Сначала пробуем извлечь URL из простой структуры
            if let landing = dict[DataManager().JSON_KEY] as? String,
               landing.isEmpty == false {
                print("✅ Found URL in simple format: \(landing)")
                return landing
            }
            
            // Если простой структуры нет, пробуем извлечь из сложной структуры с applinks
            if let applinks = dict["applinks"] as? [String: Any],
               let details = applinks["details"] as? [[String: Any]],
               !details.isEmpty,
               let url = dict["url"] as? String,
               !url.isEmpty {
                print("✅ Found URL in applinks format: \(url)")
                return url
            }
            
            print("❌ No valid URL found in response")
        } else {
            print("❌ Failed to parse JSON response")
        }
        
        throw APIError.noURLInPayload
    }
}

// MARK: - Состояние приложения (решение принимается один раз)
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var mode: AppMode?
    @Published var showNoInternetAlertForGrey = false

    private let network = NetworkMonitor.shared

    init() {
        self.mode = AppMode.loadFromStorage()
    }

    /// Вызвать один раз на старте (например, в App.onAppear)
    func bootstrap() {
        Task {
            // Повторные запуски
            if let mode = self.mode {
                if case .grey = mode, network.isConnected == false {
                    self.showNoInternetAlertForGrey = true
                }
                return
            }

            // Первый запуск — принимаем решение
            if network.isConnected == false {
                let decided: AppMode = .white
                decided.persist()
                self.mode = decided
                return
            }

            do {
                let landing = try await APIClient.fetchLandingURL(from: DataManager().SERVER_URL)
                let decided: AppMode = .grey(url: landing)
                decided.persist()
                self.mode = decided
                
                // Устанавливаем теги для веб-режима
                NotificationService.shared.setupWebModeTags(url: landing)
            } catch {
                let decided: AppMode = .white
                decided.persist()
                self.mode = decided
                
                // Устанавливаем теги для нативного режима
                NotificationService.shared.setupNativeModeTags()
            }
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    var savedGreyURL: URL? {
        guard case .grey(let urlString) = mode, let url = URL(string: urlString) else { return nil }
        return url
    }
}
