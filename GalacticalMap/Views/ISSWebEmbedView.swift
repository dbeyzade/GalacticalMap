import SwiftUI
import WebKit

struct ISSWebEmbedView: View {
    var body: some View {
        NavigationStack {
            StreetWebViewFix(url: URL(string: "https://isslivenow.com/")!)
                .ignoresSafeArea()
                .navigationBarHidden(true)
        }
    }
}

#Preview { ISSWebEmbedView() }
