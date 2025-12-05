//
//  FavoriteButton.swift
//  GalacticalMap
//
//  Reusable Favorite Button Component
//

import SwiftUI

struct FavoriteButton: View {
    let item: FavoriteItem
    let size: CGFloat
    
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var isAnimating = false
    
    init(item: FavoriteItem, size: CGFloat = 24) {
        self.item = item
        self.size = size
    }
    
    var isFavorited: Bool {
        favoritesManager.favoriteItems.contains(where: { $0.id == item.id })
    }
    
    var body: some View {
        Button {
            if isFavorited {
                favoritesManager.removeFavorite(item)
            } else {
                favoritesManager.addFavorite(item)
                isAnimating = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAnimating = false
                }
            }
        } label: {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .font(.system(size: size))
                .foregroundColor(isFavorited ? .red : .white)
                .scaleEffect(isAnimating ? 1.3 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isAnimating)
        }
    }
}

// Quick action favorite button with haptic feedback
struct QuickFavoriteButton: View {
    let type: FavoriteType
    let title: String
    let subtitle: String?
    let imageData: Data?
    let metadata: [String: Any]?
    
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var showingSuccess = false
    
    var body: some View {
        Button {
            let item = FavoriteItem(
                type: type,
                title: title,
                subtitle: subtitle,
                imageData: imageData
            )
            
            favoritesManager.addFavorite(item)
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            showingSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingSuccess = false
            }
        } label: {
            HStack {
                Image(systemName: "heart.fill")
                Text("Favorilere Ekle")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .overlay(alignment: .top) {
            if showingSuccess {
                Text("✓ Favorilere Eklendi!")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .offset(y: -40)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: showingSuccess)
    }
}

#Preview {
    VStack(spacing: 20) {
        FavoriteButton(item: FavoriteItem(
            type: .star,
            title: "Sirius",
            subtitle: "Brightest star"
        ))
        
        QuickFavoriteButton(
            type: .star,
            title: "Test Star",
            subtitle: "Test",
            imageData: nil,
            metadata: nil
        )
    }
    .padding()
    .background(Color.black)
}
