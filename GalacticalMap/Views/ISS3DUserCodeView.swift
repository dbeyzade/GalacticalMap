import SwiftUI
import WebKit

struct ISS3DUserCodeView: View {
    @State private var htmlContent: String?

    var body: some View {
        Group {
            if let htmlContent {
                ISS3DWebView(html: htmlContent)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .task { await loadHTML() }
        .navigationTitle("ISS 3D")
    }

    func loadHTML() async {
        if let url = Bundle.main.url(forResource: "ISS3DUserCode", withExtension: "html"),
           let data = try? Data(contentsOf: url),
           let str = String(data: data, encoding: .utf8) {
            htmlContent = str
            return
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let docs, let url = URL(string: "ISS3DUserCode.html", relativeTo: docs),
           let data = try? Data(contentsOf: url),
           let str = String(data: data, encoding: .utf8) {
            htmlContent = str
            return
        }
        htmlContent = nil
    }
}

private struct ISS3DWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isOpaque = false
        webview.backgroundColor = .black
        return webview
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}
