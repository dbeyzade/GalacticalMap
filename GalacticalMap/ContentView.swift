//
//  ContentView.swift
//  GalacticalMap
//
//  Created by dogukan beyzade on 8.11.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Sky
            VStack {
                Text("⭐")
                    .font(.system(size: 80))
                Text("Star Map")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .tag(0)
            .tabItem {
                Label("Sky", systemImage: "star.fill")
            }
            
            // Tab 2: Satellite
            VStack {
                Text("🛰️")
                    .font(.system(size: 80))
                Text("Satellite Tracking")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .tag(1)
            .tabItem {
                Label("Satellite", systemImage: "antenna.radiowaves.left.and.right")
            }
            
            // Tab 3: Favorites
            VStack {
                Text("❤️")
                    .font(.system(size: 80))
                Text("My Favorites")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .tag(2)
            .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }
        }
        .accentColor(.cyan)
    }
}

#Preview {
    ContentView()
}
