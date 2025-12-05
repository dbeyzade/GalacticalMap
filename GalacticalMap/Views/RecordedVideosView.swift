import SwiftUI
import AVKit

struct RecordedVideosView: View {
    @Environment(\..dismiss) var dismiss
    @State private var videos: [URL] = []
    @State private var isLoading = false
    @State private var selection: URL?
    @State private var isEditing = false
    @State private var selectedItems = Set<URL>()
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Group {
                    if isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if videos.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "video.slash")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.system(size: 36, weight: .semibold))
                            Text("No recordings")
                                .foregroundColor(.white.opacity(0.8))
                            Text("Motion-triggered recordings will appear here")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.footnote)
                        }
                    } else {
                        List {
                            ForEach(videos, id: \.self) { url in
                                if isEditing {
                                    HStack(spacing: 12) {
                                        Button {
                                            toggleSelection(url)
                                        } label: {
                                            Image(systemName: selectedItems.contains(url) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedItems.contains(url) ? .cyan : .white.opacity(0.6))
                                        }
                                        Image(systemName: "film")
                                            .foregroundColor(.white)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(url.lastPathComponent)
                                                .foregroundColor(.white)
                                            Text(displayDate(for: url) ?? "")
                                                .foregroundColor(.white.opacity(0.6))
                                                .font(.caption)
                                        }
                                        Spacer()
                                        if #available(iOS 16.0, macOS 13.0, *) {
                                            ShareLink(item: url) {
                                                Image(systemName: "square.and.arrow.up")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { toggleSelection(url) }
                                } else {
                                    NavigationLink(value: url) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "film")
                                                .foregroundColor(.white)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(url.lastPathComponent)
                                                    .foregroundColor(.white)
                                                Text(displayDate(for: url) ?? "")
                                                    .foregroundColor(.white.opacity(0.6))
                                                    .font(.caption)
                                            }
                                            Spacer()
                                            if #available(iOS 16.0, macOS 13.0, *) {
                                                ShareLink(item: url) {
                                                    Image(systemName: "square.and.arrow.up")
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .onDelete(perform: delete)
                        }
                        .listRowBackground(Color.black)
                        .scrollContentBackground(.hidden)
                        .navigationDestination(item: $selection) { url in
                            VideoPlaybackView(url: url)
                        }
                        .navigationDestination(for: URL.self) { url in
                            VideoPlaybackView(url: url)
                        }
                    }
                }
            }
            .navigationTitle("Recordings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        if isEditing {
                            Button { selectAll() } label: {
                                Text("Select All").foregroundColor(.white)
                            }
                            Button { deleteSelected() } label: {
                                Text("Delete Selected").foregroundColor(.red)
                            }
                        }
                        Button { isEditing.toggle() } label: {
                            Image(systemName: isEditing ? "checkmark.circle" : "pencil.circle")
                                .foregroundColor(.white)
                        }
                        Button { loadVideos() } label: {
                            Image(systemName: "arrow.clockwise").foregroundColor(.white)
                        }
                    }
                }
            }
            .onAppear { loadVideos() }
        }
    }
    private func loadVideos() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            let dir = fm.urls(for: .documentDirectory, in: .userDomainMask).first
            var list: [URL] = []
            if let dir = dir, let urls = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles]) {
                list = urls.filter { $0.pathExtension.lowercased() == "mov" }
                    .sorted { (a, b) -> Bool in
                        let va = try? a.resourceValues(forKeys: [.creationDateKey])
                        let vb = try? b.resourceValues(forKeys: [.creationDateKey])
                        return (va?.creationDate ?? Date.distantPast) > (vb?.creationDate ?? Date.distantPast)
                    }
            }
            DispatchQueue.main.async {
                self.videos = list
                self.isLoading = false
            }
        }
    }
    private func delete(at offsets: IndexSet) {
        let fm = FileManager.default
        for i in offsets { try? fm.removeItem(at: videos[i]) }
        videos.remove(atOffsets: offsets)
    }
    private func deleteSelected() {
        guard !selectedItems.isEmpty else { return }
        let fm = FileManager.default
        for url in selectedItems { try? fm.removeItem(at: url) }
        videos.removeAll { selectedItems.contains($0) }
        selectedItems.removeAll()
    }
    private func selectAll() {
        selectedItems = Set(videos)
    }
    private func toggleSelection(_ url: URL) {
        if selectedItems.contains(url) { selectedItems.remove(url) } else { selectedItems.insert(url) }
    }
    private func displayDate(for url: URL) -> String? {
        let rv = try? url.resourceValues(forKeys: [.creationDateKey])
        guard let d = rv?.creationDate else { return nil }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
}

struct VideoPlaybackView: View, Identifiable {
    let url: URL
    var id: URL { url }
    @State private var player: AVPlayer?
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let p = player { VideoPlayer(player: p) } else { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
        }
        .navigationTitle(url.lastPathComponent)
        .onAppear {
            let p = AVPlayer(url: url)
            p.play()
            player = p
        }
        .onDisappear { player?.pause() }
    }
}