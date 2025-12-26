//
//  WfdView.swift
//  DF774
//
//  Created by IGOR on 16/12/2025.
//

import SwiftUI
import WebKit

// MARK: - Публичный контейнер для использования в UI
struct WebContainerView: View {
    let initialURL: URL

    var body: some View {
        WebViewRepresentable(initialURL: initialURL)
            .ignoresSafeArea()
    }
}

// MARK: - Представимая обёртка
struct WebViewRepresentable: UIViewRepresentable {
    let initialURL: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = false
        webView.customUserAgent = "Mozilla/5.0 (Linux; Android 11; AOSP on x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/89.0.4389.105 Mobile Safari/537.36"

        loadCookies(into: webView)

        webView.load(URLRequest(url: initialURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { }

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator()
    }

    private func loadCookies(into webView: WKWebView) {
        if let data = UserDefaults.standard.object(forKey: "cookie") as? Data,
           let cookies = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [HTTPCookie] {
            for cookie in cookies {
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
            }
        }
    }
}

// MARK: - Координатор
final class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let cookies = HTTPCookieStorage.shared.cookies,
           let data = try? NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: "cookie")
        }

        if let current = webView.url?.absoluteString, !current.isEmpty {
            UserDefaults.standard.set(current, forKey: "saved_url")
        }
    }

    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        completionHandler(nil)
    }
}

