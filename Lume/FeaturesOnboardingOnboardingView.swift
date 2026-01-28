//
//  OnboardingView.swift
//  Museum Companion
//
//  Three-screen onboarding flow
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Discover",
            description: "Point your camera at any painting and instantly learn its story.",
            systemImage: "camera.viewfinder"
        ),
        OnboardingPage(
            title: "Understand",
            description: "Get detailed information about the artist, period, and cultural context.",
            systemImage: "book.closed.fill"
        ),
        OnboardingPage(
            title: "Feel",
            description: "Experience each artwork through emotional narratives that bring art to life.",
            systemImage: "heart.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.black : Color.black.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 32)
                
                // Limits info (only on last page)
                if currentPage == pages.count - 1 {
                    limitsInfo
                        .transition(.opacity)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 24)
                }
                
                // Continue button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.system(.body, design: .default))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                
                // Skip button
                if currentPage < pages.count - 1 {
                    Button {
                        hasCompletedOnboarding = true
                    } label: {
                        Text("Skip")
                            .font(.system(.body))
                            .foregroundColor(.black.opacity(0.5))
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .animation(.easeInOut, value: currentPage)
    }
    
    // MARK: - Limits Info
    
    private var limitsInfo: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "gift.fill")
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free: 3 scans per day")
                        .font(.system(.subheadline, design: .default))
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    Text("Resets daily at midnight")
                        .font(.system(.caption))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pro: Unlimited scans")
                        .font(.system(.subheadline, design: .default))
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    
                    Text("€2.99/month or €19.99/year")
                        .font(.system(.caption))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.02))
                )
        )
    }
}

// MARK: - Onboarding Page

struct OnboardingPage {
    let title: String
    let description: String
    let systemImage: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundColor(.black)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.custom("NewYork", size: 48))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text(page.description)
                    .font(.system(.title3))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
