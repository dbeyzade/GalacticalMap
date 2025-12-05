import SwiftUI

struct NASAVisibleEarthView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showTip = true
    var body: some View {
        ZStack(alignment: .topLeading) {
            GyroWebView(html: nil, urlString: "https://eyes.nasa.gov/apps/earth/#/")
                .ignoresSafeArea()
            if showTip {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Text("Tip: Tap satellites to select them.")
                            .font(.caption)
                            .foregroundColor(.white)
                        Button { showTip = false } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
            }
        }
        .navigationTitle("Visible Earth")
        .navigationBarTitleDisplayMode(.inline)
    }
}
