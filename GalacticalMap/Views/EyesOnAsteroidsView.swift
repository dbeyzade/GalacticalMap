import SwiftUI
import WebKit

struct EyesOnAsteroidsView: View {
    var body: some View {
        AsteroidsWebView(url: URL(string: "https://eyes.nasa.gov/apps/asteroids/")!)
            .ignoresSafeArea()
            .navigationTitle("Eyes on Asteroids")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AsteroidsWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
}
