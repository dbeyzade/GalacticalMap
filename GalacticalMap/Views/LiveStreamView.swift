//
//  LiveStreamView.swift
//  GalacticalMap
//
//  Canlı yayın izleme ve ekran yansıtma
//

import SwiftUI
import WebKit
import AVKit
import AVFoundation
import Foundation
import UIKit
import MapKit
import Combine
import SceneKit

struct LiveStreamView: View {
    let streamURL: String
    var isMinimal: Bool = true
    @Environment(\.dismiss) var dismiss
    @State private var isFullScreen = false
    @State private var showingAirPlayPicker = false
    @State private var isMuted = false
    @State private var webViewRef: WKWebView?
    @State private var avPlayerRef: AVPlayer?
    @State private var showSnapshotConfirmation = false
    @State private var bonjourBrowser: NetServiceBrowser?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Web görünümü veya video player
                    if streamURL.contains("youtube") || streamURL.contains("youtu.be") {
                        YouTubePlayerView(url: streamURL)
                    } else if streamURL.contains(".m3u8") {
                        VideoPlayerView(url: streamURL, isMuted: $isMuted, onPlayerReady: { player in
                            avPlayerRef = player
                        })
                    } else {
                        WebPagePlayerView(url: streamURL, isMuted: $isMuted, onReady: { webView in
                            webViewRef = webView
                        })
                    }
                    
                    if !isMinimal {
                        StreamControlsView(isMuted: $isMuted, onSnapshot: captureSnapshot)
                            .padding()
                            .background(.ultraThinMaterial)
                    }
                }
                
                if showSnapshotConfirmation {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Saved")
                                .foregroundColor(.white)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(14)
                        .padding(.bottom, 24)
                    }
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { if !isMinimal {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.white) }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isFullScreen.toggle() } label: { Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right").foregroundColor(.white) }
                }
            } }
            .sheet(isPresented: Binding(get: { !isMinimal && showingAirPlayPicker }, set: { showingAirPlayPicker = $0 })) {
                AirPlayPickerView()
            }
            .navigationBarHidden(isMinimal)
            .onAppear {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playback, mode: .default, options: [.allowAirPlay])
                try? session.setActive(true)
                let browser = NetServiceBrowser()
                bonjourBrowser = browser
                browser.searchForServices(ofType: "_airplay._tcp.", inDomain: "local.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.bonjourBrowser?.stop()
                }
            }
        }
    }
}

struct YouTubePlayerView: UIViewRepresentable {
    let url: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 15.0, *) {
            config.allowsAirPlayForMediaPlayback = true
        }
        if #available(iOS 15.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let videoID: String = {
            if let range = url.range(of: "watch?v=") {
                return String(url[range.upperBound...]).components(separatedBy: "&").first ?? ""
            }
            if let hostRange = url.range(of: "youtu.be/") {
                return String(url[hostRange.upperBound...]).components(separatedBy: "?").first ?? ""
            }
            if let embedRange = url.range(of: "/embed/") {
                return String(url[embedRange.upperBound...]).components(separatedBy: "?").first ?? ""
            }
            return url
        }()
        
        let embedSrc = "https://www.youtube-nocookie.com/embed/\(videoID)?autoplay=1&playsinline=1&rel=0&controls=0&modestbranding=1&fs=1"
        let html = """
        <html>
          <head>
            <meta name='viewport' content='initial-scale=1, maximum-scale=1'>
            <style>html,body{margin:0;height:100%;background:black}</style>
          </head>
          <body>
            <iframe id='player' type='text/html' width='100%' height='100%' src='\(embedSrc)' frameborder='0' allow='accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share' allowfullscreen></iframe>
          </body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

struct WebPagePlayerView: UIViewRepresentable {
    let url: String
    @Binding var isMuted: Bool
    let onReady: (WKWebView) -> Void
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebPagePlayerView
        init(_ parent: WebPagePlayerView) { self.parent = parent }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let urlLower = parent.url.lowercased()
            let isN2YO = urlLower.contains("n2yo.com/space-station")
            let isISSTracker = urlLower.contains("isstracker")
            let isWhereTheISSAt = urlLower.contains("wheretheiss.at")
            let js = isN2YO ? """
            (function(){
              var style=document.createElement('style');
              style.innerHTML='html,body{margin:0;height:100%;background:black;overflow:hidden} header,nav,footer,.navbar,.topbar,#menu,.sidebar,.logo,[class*="cookie"],[class*="banner"],[class*="promo"],[class*="sponsor"],[class*="donate"],[class*="ad"],[id*="ad"],[class*="ads"],[id*="ads"],.fb-like,.likebox{display:none !important;} .leaflet-container{width:100% !important;height:100% !important}';
              document.head.appendChild(style);
              function removeMedia(){
                Array.from(document.querySelectorAll('iframe,video,ins.adsbygoogle,canvas,div')).forEach(function(el){
                  var id=(el.id||'').toLowerCase();
                  var cls=(el.className||'').toLowerCase();
                  var src=(el.getAttribute('src')||'').toLowerCase();
                  if(/youtube|youtu\\.be|sen\\.com|doubleclick|googlesyndication|googleads|adservice|adroll|adnxs|taboola|outbrain/.test(src) || /cesium/.test(id) || /cesium/.test(cls)){
                    el.remove();
                  }
                });
              }
              function arrange(){
                var map=document.querySelector('.leaflet-container,#map,div[id*="map"],canvas[id*="map"]');
                if(!map) return;
                var mapContainer=map.closest('div,section,article')||map;
                var wrap=document.getElementById('gm-wrap');
                if(!wrap){
                  wrap=document.createElement('div');
                  wrap.id='gm-wrap';
                  wrap.style.position='fixed';
                  wrap.style.top='0';
                  wrap.style.left='0';
                  wrap.style.width='100%';
                  wrap.style.height='100%';
                  wrap.style.background='black';
                  document.body.appendChild(wrap);
                }
                Array.from(document.body.children).forEach(function(c){ if(c!==wrap){ c.style.display='none'; } });
                if(mapContainer.parentNode!==wrap){ wrap.appendChild(mapContainer); }
                mapContainer.style.position='absolute';
                mapContainer.style.top='0';
                mapContainer.style.left='0';
                mapContainer.style.width='100%';
                mapContainer.style.height='100%';
                map.style.width='100%';
                map.style.height='100%';
              }
              function apply(){removeMedia();arrange();}
              apply();
              var mo=new MutationObserver(apply);mo.observe(document.documentElement,{childList:true,subtree:true});
            })();
            """ : isISSTracker ? """
            (function(){
              var style=document.createElement('style');
              style.innerHTML='html,body{margin:0;height:100%;background:black;overflow:hidden} #app,#root{height:100%} .leaflet-container,div[id*="map"],div[class*="map"],canvas{width:100% !important;height:100% !important} .mobile_sidebar,.sidebar,.sidebar-tabs,.sidebar-content,.progress-bar,.cat-container,ins.adsbygoogle,[id^="google_ads_iframe"],[id^="aswift"],[class*="banner"],[class*="ads"],[id*="ad"]{display:none !important;}';
              document.head.appendChild(style);
              function isolate(){
                var mapEl=document.querySelector('canvas, .leaflet-container, #map, div[id*="map"]');
                var container=document.querySelector('.sidebar-map') || (mapEl && mapEl.closest('div,section,article')) || mapEl;
                if(!mapEl || !container){ return; }
                if(window.__gm_iso_done){ return; }
                container.style.position='fixed';
                container.style.top='0';
                container.style.left='0';
                container.style.width='100%';
                container.style.height='100%';
                container.style.zIndex='999999';
                mapEl.style.width='100%';
                mapEl.style.height='100%';
                document.documentElement.style.overflow='hidden';
                document.body.style.overflow='hidden';
                window.__gm_iso_done=true;
              }
              function clean(){
                var selectors='iframe,ins.adsbygoogle,[id^="google_ads_iframe"],[id^="aswift"],[data-google-query-id],.google-auto-placed,[data-ad-client],[data-testid*="ad"],.cat-container iframe.fallback';
                Array.from(document.querySelectorAll(selectors)).forEach(function(n){ var p=n.closest('div,section,aside,footer'); (p||n).remove(); });
                var topAds = Array.from(document.querySelectorAll('div,section,header')).filter(function(el){
                  var r = el.getBoundingClientRect();
                  var hasAd = /google_ads_iframe|adsbygoogle|ad-|banner/i.test(el.innerHTML||'') || el.querySelector('iframe[src*="googlesyndication"], iframe[src*="doubleclick"], iframe[src*="pubads"], iframe[src*="securepubads"]');
                  return hasAd && r.top < 160;
                });
                topAds.forEach(function(el){ var p=el.closest('div,section,header'); (p||el).remove(); });
                var bottomAds = Array.from(document.querySelectorAll('div,section,footer')).filter(function(el){
                  var r = el.getBoundingClientRect();
                  var hasAd = /google_ads_iframe|adsbygoogle|ad-|banner/i.test(el.innerHTML||'') || el.querySelector('iframe[src*="googlesyndication"], iframe[src*="doubleclick"]');
                  return hasAd && r.bottom > (window.innerHeight - 120);
                });
                bottomAds.forEach(function(el){ var p=el.closest('div,section,footer'); (p||el).remove(); });
                ['nav','footer'].forEach(function(tag){ var e=document.querySelector(tag); if(e){ e.remove(); }});
                Array.from(document.querySelectorAll('*')).forEach(function(el){ if(el.shadowRoot){ var a=el.shadowRoot.querySelectorAll('iframe, ins.adsbygoogle, [id^="google_ads_iframe"], [id^="aswift"]'); a.forEach(function(n){ n.remove(); }); } });
                Array.from(document.querySelectorAll('audio')).forEach(function(a){ a.muted=true; a.volume=0; try{ a.pause(); }catch(e){} });
              }
              isolate(); clean();
              var mo=new MutationObserver(function(){ clean(); });
              mo.observe(document.documentElement,{childList:true,subtree:true});
              setInterval(function(){ clean(); }, 1500);

              var info=document.getElementById('gm-info');
              if(!info){
                info=document.createElement('div');
                info.id='gm-info';
                info.style.position='fixed';
                info.style.top='8px';
                info.style.left='8px';
                info.style.background='rgba(0,0,0,0.7)';
                info.style.color='#0ff';
                info.style.font='12px -apple-system,Segoe UI,Roboto';
                info.style.padding='6px 8px';
                info.style.borderRadius='6px';
                info.style.zIndex='1000000';
                info.style.pointerEvents='none';
                info.style.display='none';
                document.body.appendChild(info);
              }
              document.addEventListener('click',function(e){
                var el=e.target;
                var txt='id='+ (el.id||'(yok)') +' class='+(el.className||'(yok)')+' tag='+el.tagName;
                info.textContent=txt;
                info.style.display='block';
                clearTimeout(window.__gmInfoTimer);
                window.__gmInfoTimer=setTimeout(function(){ info.style.display='none'; }, 2000);
              },true);
            })();
            """ : isWhereTheISSAt ? """
            (function(){
              var style=document.createElement('style');
              style.innerHTML='html,body{margin:0;padding:0;height:100%;width:100%;overflow:hidden;background:black}' +
                              '#map, .leaflet-container, #google_map, canvas.leaflet-zoom-animated{position:fixed !important;top:0 !important;left:0 !important;width:100vw !important;height:100vh !important;z-index:1000 !important}' +
                              'header,footer,nav,.navbar,.sidebar,#sidebar,.col-md-4,.info-panel,.footer-links{display:none !important}' +
                              '.leaflet-control-container,.leaflet-control-zoom,.leaflet-control-attribution{display:none !important}' +
                              'a[href*="about"],a[href*="blog"],a[href*="api"],a[href*="linzig"]{display:none !important}';
              document.head.appendChild(style);

              function fix(){
                  var map = document.querySelector('#map, .leaflet-container, #google_map, canvas.leaflet-zoom-animated');
                  if(map){
                      var container = map.closest('#map, .leaflet-container') || map;
                      container.style.position='fixed';
                      container.style.top='0';
                      container.style.left='0';
                      container.style.width='100vw';
                      container.style.height='100vh';
                  }
                  var nodes = Array.from(document.querySelectorAll('div,span,img'));
                  nodes.forEach(function(n){
                    var t=(n.innerText||'').toLowerCase();
                    if(t.indexOf('bu sayfa google haritalar')>-1 || t.indexOf('google maps')>-1){
                      var p=n.closest('[role="dialog"],div,section,aside,footer')||n; (p||n).style.display='none';
                    }
                  });
                  // Sadece overlay ve popup'ları gizle, harita canvas ve .gm-style asla gizlenmesin
                  Array.from(document.querySelectorAll('.gm-style-iw,.gm-style-cc,.gm-style-mtc,.gm-bundled-control,.gm-ui-hover-effect,[role="dialog"],[class*="gm-control"]')).forEach(function(e){
                    if(!e.classList.contains('gm-style')) e.style.display='none';
                  });
                  window.dispatchEvent(new Event('resize'));
              }

              fix();
              setTimeout(fix, 500);
              setTimeout(fix, 1500);
              setTimeout(fix, 3000);
              var mo=new MutationObserver(fix);
              mo.observe(document.body,{childList:true,subtree:true});
            })();
            """ : """
            (function(){
              var style=document.createElement('style');
              style.innerHTML='header,nav,footer,.header,.topbar,[class*="Header"],[class*="Nav"],[class*="navbar"],[class*="brand"],[class*="cookie"],[class*="ad"],[id*="ad"],[class*="ads"],[id*="ads"],[class*="advert"],[id*="advert"],[class*="banner"],[id*="banner"],[class*="promo"],[id*="promo"],[class*="sponsor"],[id*="sponsor"],[class*="donate"],[id*="donate"],[class*="coffee"],[id*="coffee"],[class*="support"],[id*="support"],.sidebar,.logo,.page-header,.sticky,[style*="position: fixed"],[style*="position: sticky"]{display:none !important;} html,body{margin:0;background:black;overflow:hidden} video{width:100% !important;height:100% !important;object-fit:contain !important;position:relative !important;}';
              document.head.appendChild(style);
              function removeByText(){
                var needles=['buy us a coffee','google cloud','cloud run','kaynak kodundan yönetilen uygulamaya','sunucu olmadan','dakikalar içinde geçin','sponsor','advertisement','usdtry','gcm yatırım'];
                var nodes=document.querySelectorAll('div,section,aside,footer');
                nodes.forEach(function(n){var t=(n.textContent||'').toLowerCase();
                  if(needles.some(function(k){return t.indexOf(k)>-1;})){
                    var p=n.closest('div,section,aside,footer');
                    (p||n).remove();
                  }
                });
                Array.from(document.querySelectorAll('a')).forEach(function(a){var href=(a.getAttribute('href')||'').toLowerCase();if(/buymeacoffee|googleads|doubleclick|googlesyndication|cloud\\.google\\.com|findandloc|gcmforex|gcmyatirim/.test(href)){var x=a.closest('div,section,aside,footer');(x||a).remove();}});
              }
              function removeFrames(){
                Array.from(document.querySelectorAll('iframe,ins.adsbygoogle')).forEach(function(f){
                  var src=(f.getAttribute('src')||'').toLowerCase();
                  if(/doubleclick|googlesyndication|googleads|googletagservices|adservice|adroll|adnxs|ib\\.adnxs|amazon-adsystem|refinery89|prebid|pagead|pagead2|adclick|google_ads_iframe/.test(src)){
                    var p=f.closest('div,section,aside');(p||f).remove();
                  }
                });
                Array.from(document.querySelectorAll('[id^="google_ads_iframe"],[id^="aswift"],[data-google-query-id],.google-auto-placed,[data-ad-client],[data-testid*="ad"],[class*="ads"],[class*="ad"],[id*="ad"]')).forEach(function(n){
                  var p=n.closest('div,section,aside');(p||n).remove();
                });
              }
              function maximizeVideo(){
                var v=document.querySelector('video');
                if(!v) return;
                var container=v.closest('div,section,article')||v;
                var parent=container.parentNode;
                if(parent){Array.from(parent.children).forEach(function(c){if(c!==container){c.style.display='none';}})}
                container.style.position='fixed';
                container.style.top='0';
                container.style.left='0';
                container.style.width='100%';
                container.style.height='100%';
                v.style.width='100%';
                v.style.height='100%';
                v.style.objectFit='contain';
              }
              function maximizeMap(){
                var map=document.querySelector('.leaflet-container,#map,div[id*="map"],canvas[id*="map"]');
                if(!map) return;
                var container=map.closest('#app,#root,main,section,article,div')||document.body;
                Array.from(document.querySelectorAll('body *')).forEach(function(el){
                  if(el!==map && !el.contains(map)){
                    el.style.display='none';
                  }
                });
                var fixed=(map.closest('div')||map);
                fixed.style.position='fixed';
                fixed.style.top='0';
                fixed.style.left='0';
                fixed.style.width='100%';
                fixed.style.height='100%';
                map.style.width='100%';
                map.style.height='100%';
              }
              function clean(){removeFrames();removeByText();maximizeMap();maximizeVideo();}
              clean();
              var mo=new MutationObserver(function(){clean();});
              mo.observe(document.documentElement,{childList:true,subtree:true});
              function apply(){
                document.querySelectorAll('video').forEach(function(v){v.muted=%@; v.controls=false;});
                document.querySelectorAll('audio').forEach(function(a){a.muted=true;a.volume=0;a.pause();});
              }
              apply();
              setInterval(function(){apply();clean();}, 1000);
            })();
            """
            let muted = parent.isMuted ? "true" : "false"
            webView.evaluateJavaScript(String(format: js, muted), completionHandler: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 15.0, *) {
            config.allowsAirPlayForMediaPlayback = true
        }
        if #available(iOS 15.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        let isWhereTheISSAt = url.lowercased().contains("wheretheiss.at")
        let isAstroViewer = url.lowercased().contains("astroviewer.net")
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        if isWhereTheISSAt {
            webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        }
        let rules = """
        [
          {"trigger":{"url-filter":".*(doubleclick|securepubads|pubads|googlesyndication|googleads|googletagservices|googletagmanager|pagead|pagead2|adservice|adroll|adnxs|amazon-adsystem|refinery89|prebid|taboola|outbrain|buymeacoffee|tpc\\\\.googlesyndication\\\\.com|adsafeprotected|cloud\\\\.google\\\\.com|findandloc).*"},"action":{"type":"block"}},
          {"trigger":{"url-filter":".*"},"action":{"type":"css-display-none","selector":"[class*='ad'],[id*='ad'],.adsbygoogle,[class*='ads'],[id*='ads'],[class*='advert'],[id*='advert'],[class*='banner'],[id*='banner'],[class*='promo'],[id*='promo'],[class*='sponsor'],[id*='sponsor'],[class*='donate'],[id*='donate'],[class*='cookie'],[id*='cookie'],[class*='support'],[id*='support'],.sticky,[aria-label*='ad'],iframe[id^='google_ads_iframe'],[id^='google_ads_iframe'],[id^='aswift'],ins.adsbygoogle,[data-google-query-id],[data-ad-client]"}}
        ]
        """
        if !isAstroViewer && !isWhereTheISSAt {
            WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "BlockAdsRules", encodedContentRuleList: rules) { list, _ in
                if let list = list {
                    webView.configuration.userContentController.add(list)
                }
            }
        }
        onReady(webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let lower = url.lowercased()
        let isAstroViewer = lower.contains("astroviewer.net")
        let request: URLRequest? = {
            guard let target = URL(string: url) else { return nil }
            var req = URLRequest(url: target)
            if isAstroViewer {
                req.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
            }
            return req
        }()
        if let current = uiView.url?.absoluteString, current != url {
            if let req = request { uiView.load(req) }
        } else if uiView.url == nil {
            if let req = request { uiView.load(req) }
        }
        uiView.evaluateJavaScript("document.querySelectorAll('video').forEach(v=>v.muted=\(isMuted ? 1 : 0))", completionHandler: nil)
    }
}

struct VideoPlayerView: View {
    let url: String
    @Binding var isMuted: Bool
    let onPlayerReady: (AVPlayer) -> Void
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear {
            if let videoURL = URL(string: url) {
                let newPlayer = AVPlayer(url: videoURL)
                newPlayer.isMuted = isMuted
                newPlayer.allowsExternalPlayback = true
                newPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true
                newPlayer.play()
                player = newPlayer
                onPlayerReady(newPlayer)
            }
        }
        .onChange(of: isMuted) { _, newValue in
            player?.isMuted = newValue
        }
        .onDisappear {
            player?.pause()
        }
    }
}

struct ISSMapOnlyView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 80)
    )
    @State private var issCoordinate: CLLocationCoordinate2D = .init(latitude: 0, longitude: 0)
    @State private var lastPositions: [ISSPoint] = []
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var showVideo = false
    private let videoURL = "https://www.youtube.com/watch?v=21X5lGlDOfg"
    @Environment(\.openURL) private var openURL
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: [ISSPoint(coord: issCoordinate)]) { item in
                MapAnnotation(coordinate: item.coord) {
                    Image(systemName: "dot.circle.fill").foregroundColor(.cyan).font(.system(size: 18))
                }
            }
            .ignoresSafeArea()
            .background(Color.black)

            VStack {
                HStack {
                    Text("LIVE")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        if let url = URL(string: videoURL) { openURL(url) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "video.fill")
                            Text("ISS Live Video")
                                .font(.caption)
                        }
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .onAppear { fetchISS() }
        .onReceive(timer) { _ in fetchISS() }
        .sheet(isPresented: $showVideo) { EmptyView() }
    }
    struct ISSPoint: Identifiable {
        let id = UUID()
        let coord: CLLocationCoordinate2D
    }
    private func fetchISS() {
        guard let url = URL(string: "http://api.open-notify.org/iss-now.json") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let pos = json["iss_position"] as? [String: Any],
                  let latStr = pos["latitude"] as? String,
                  let lonStr = pos["longitude"] as? String,
                  let lat = Double(latStr),
                  let lon = Double(lonStr) else { return }
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            DispatchQueue.main.async {
                issCoordinate = coord
                region.center = coord
            }
        }.resume()
    }
}

struct ISSGlobe3DView: View {
    @State private var scene = SCNScene()
    @State private var earthNode = SCNNode()
    @State private var issNode = SCNNode()
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    var body: some View {
        ZStack {
            SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
                .ignoresSafeArea()
                .background(Color.black)
                .onAppear { setupScene(); fetchISS() }
                .onReceive(timer) { _ in fetchISS() }
        }
    }
    private func setupScene() {
        scene.background.contents = UIColor.black
        let sphere = SCNSphere(radius: 1.0)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.systemBlue
        mat.specular.contents = UIColor.white
        mat.shininess = 0.1
        sphere.firstMaterial = mat
        earthNode.geometry = sphere
        scene.rootNode.addChildNode(earthNode)

        let rotate = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi*2, z: 0, duration: 60))
        earthNode.runAction(rotate)

        let issGeom = SCNSphere(radius: 0.03)
        let issMat = SCNMaterial()
        issMat.diffuse.contents = UIColor.cyan
        issGeom.firstMaterial = issMat
        issNode.geometry = issGeom
        scene.rootNode.addChildNode(issNode)

        let cam = SCNCamera()
        cam.zFar = 100
        let camNode = SCNNode()
        camNode.camera = cam
        camNode.position = SCNVector3(0, 0, 3.0)
        scene.rootNode.addChildNode(camNode)
    }
    private func placeISS(lat: Double, lon: Double) {
        let r: Double = 1.02
        let latR = lat * .pi / 180.0
        let lonR = lon * .pi / 180.0
        let x = r * cos(latR) * cos(lonR)
        let y = r * sin(latR)
        let z = r * cos(latR) * sin(lonR)
        issNode.position = SCNVector3(x, y, z)
    }
    private func fetchISS() {
        guard let url = URL(string: "http://api.open-notify.org/iss-now.json") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let pos = json["iss_position"] as? [String: Any],
                  let latStr = pos["latitude"] as? String,
                  let lonStr = pos["longitude"] as? String,
                  let lat = Double(latStr),
                  let lon = Double(lonStr) else { return }
            DispatchQueue.main.async { placeISS(lat: lat, lon: lon) }
        }.resume()
    }
}

struct StreamControlsView: View {
    @Binding var isMuted: Bool
    @State private var showingInfo = false
    let onSnapshot: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            Button {
                isMuted.toggle()
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button {
                showingInfo.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                    Text("Stream Info")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            
            Spacer()
            
            Button {
                onSnapshot()
            } label: {
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .sheet(isPresented: $showingInfo) {
            StreamInfoView()
        }
    }
}

extension LiveStreamView {
    func captureSnapshot() {
        if let webView = webViewRef {
            let config = WKSnapshotConfiguration()
            config.rect = webView.bounds
            webView.takeSnapshot(with: config) { image, _ in
                guard let image = image else { return }
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                showSavedToast()
            }
            return
        }
        if let player = avPlayerRef, let item = player.currentItem {
            let asset = item.asset
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = player.currentTime()
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                let uiImage = UIImage(cgImage: cgImage)
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                showSavedToast()
            }
        }
    }
    
    func showSavedToast() {
        withAnimation { showSnapshotConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSnapshotConfirmation = false }
        }
    }
}

struct StreamInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Stream Details") {
                    HStack {
                        Text("Status")
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("Live")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        Text("Quality")
                        Spacer()
                        Text("HD 1080p")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Viewers")
                        Spacer()
                        Text("12,543")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Features") {
                    HStack {
                        Image(systemName: "airplayvideo")
                        Text("AirPlay Support")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Image(systemName: "tv")
                        Text("Screen Mirroring")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Image(systemName: "4k.tv")
                        Text("4K Support")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Stream Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AirPlayPickerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        // AirPlay button
        let airPlayButton = AVRoutePickerView()
        airPlayButton.tintColor = .white
        airPlayButton.activeTintColor = .cyan
        airPlayButton.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(airPlayButton)
        viewController.view.backgroundColor = .black
        
        NSLayoutConstraint.activate([
            airPlayButton.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            airPlayButton.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            airPlayButton.widthAnchor.constraint(equalToConstant: 200),
            airPlayButton.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // Add title
        let label = UILabel()
        label.text = "Select a Device"
        label.textColor = .white
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: airPlayButton.topAnchor, constant: -40)
        ])
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    LiveStreamView(streamURL: "https://www.youtube.com/watch?v=21X5lGlDOfg")
}
