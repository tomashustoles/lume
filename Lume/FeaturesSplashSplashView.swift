//
//
//  SplashView.swift
//  Lume
//
//  Simple splash screen that shows on every launch
//

import SwiftUI

struct SplashView: View {
    @Binding var isShowingSplash: Bool
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            // Content box - centered on screen but internally left-aligned
            VStack(alignment: .leading, spacing: 40) {
                // Sparkles icon in rectangle - matching paywall style
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.black)
                }
                .scaleEffect(showContent ? 1.0 : 0.9)
                .opacity(showContent ? 1.0 : 0.0)
                
                // Main instruction - left aligned
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recognize\nAny Artwork")
                        .font(.custom("NewYork", size: 46))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Text("Point your camera at any painting\nand discover its story instantly")
                        .font(.system(.title3))
                        .foregroundColor(.black.opacity(0.6))
                }
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 15)
            }
            .padding(.horizontal, 24)
        }
        .task {
            await animateAndDismiss()
        }
    }
    
    // MARK: - Animation Sequence
    
    private func animateAndDismiss() async {
        // Ensure we're not already dismissed
        guard isShowingSplash else { return }
        
        // Fade in content
        withAnimation(.easeOut(duration: 0.6)) {
            showContent = true
        }
        
        // Hold for user to read
        do {
            try await Task.sleep(for: .seconds(2.5))
        } catch {
            // Task was cancelled, dismiss immediately
            isShowingSplash = false
            return
        }
        
        // Check if still showing
        guard isShowingSplash else { return }
        
        // Fade out
        withAnimation(.easeOut(duration: 0.5)) {
            showContent = false
        }
        
        do {
            try await Task.sleep(for: .seconds(0.5))
        } catch {
            // Task was cancelled
            isShowingSplash = false
            return
        }
        
        // Dismiss splash
        isShowingSplash = false
    }
}

// MARK: - Preview

#Preview {
    SplashView(isShowingSplash: .constant(true))
}



