import SwiftUI
import WebKit
import CoreLocation

struct StreetViewConfig {
    static var apiKey: String = ""
}

struct StreetInlineView: UIViewRepresentable {
    let latitude: Double
    let longitude: Double
    let heading: Double
    let pitch: Double
    let fov: Double
    var onLoaded: (() -> Void)? = nil
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let html = buildHTML()
        uiView.loadHTMLString(html, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(onLoaded: onLoaded) }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let onLoaded: (() -> Void)?
        init(onLoaded: (() -> Void)?) { self.onLoaded = onLoaded }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { onLoaded?() }
    }
    
    private func buildHTML() -> String {
        let key = StreetViewConfig.apiKey
        let loader = "<div id=loader style=\"position:fixed;inset:0;display:flex;align-items:center;justify-content:center;background:#000;z-index:9;color:#0ff;font-family:monospace\">Loading Street View...</div>"
        let container = "<div id=sv style=\"position:fixed;inset:0\"></div>"
        let js = """
        <script src="https://maps.googleapis.com/maps/api/js?key=\(key)&v=quarterly&language=en&region=US"></script>
        <script>
        (function(){
          function init(){
            var pos = {lat: \\(LAT), lng: \\(LON)};
            var pano = new google.maps.StreetViewPanorama(document.getElementById('sv'), {
              position: pos,
              pov: { heading: \\(HEADING), pitch: \\(PITCH) },
              zoom: Math.max(0, Math.min(5, (\
                (\
                  (\
                    (\
                      \\(FOV)
                    )
                  )
                )
              )))
            });
            document.getElementById('loader').style.display='none';
          }
          window.initStreet = init;
        })();
        </script>
        <script>document.addEventListener('DOMContentLoaded', function(){ if(window.google && google.maps){ initStreet(); } else { setTimeout(function(){ if(window.google && google.maps){ initStreet(); } }, 300); } });</script>
        """
        let html = """
        <!DOCTYPE html>
        <html><head><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>html,body{margin:0;padding:0;background:#000;}</style>
        </head><body>
        \\(LOADER)
        \\(CONTAINER)
        \\(JS)
        </body></html>
        """
        .replacingOccurrences(of: "\\(LAT)", with: String(latitude))
        .replacingOccurrences(of: "\\(LON)", with: String(longitude))
        .replacingOccurrences(of: "\\(HEADING)", with: String(Int(heading)))
        .replacingOccurrences(of: "\\(PITCH)", with: String(Int(pitch)))
        .replacingOccurrences(of: "\\(FOV)", with: String(Int(fov)))
        .replacingOccurrences(of: "\\(LOADER)", with: loader)
        .replacingOccurrences(of: "\\(CONTAINER)", with: container)
        .replacingOccurrences(of: "\\(JS)", with: js)
        return html
    }
}
