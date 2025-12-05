import SwiftUI
import WebKit

struct ISSUserCodeView: View {
    @State private var htmlContent: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let html = htmlContent {
                    HTMLWebView(html: html)
                        .ignoresSafeArea()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.4))
                        Text("ISS user code not found")
                            .foregroundColor(.white)
                        Text("Please add 'ISSUserCode.html' to the project or copy it into the App Documents folder")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            .navigationTitle("🛰️ ISS Live")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.white) }
                }
            }
        }
        .task { await loadHTML() }
    }
    
    func loadHTML() async {
        if let url = Bundle.main.url(forResource: "ISSUserCode", withExtension: "html"),
           let data = try? Data(contentsOf: url),
           let str = String(data: data, encoding: .utf8) {
            htmlContent = str
            return
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let docs, let url = URL(string: "ISSUserCode.html", relativeTo: docs),
           let data = try? Data(contentsOf: url),
           let str = String(data: data, encoding: .utf8) {
            htmlContent = str
            return
        }
        htmlContent = nil
    }
}

struct HTMLWebView: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 15.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.bounces = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    ISSUserCodeView()
}
