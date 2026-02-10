//
//  OnboardingView.swift
//  Museum Companion
//
//  Three-screen onboarding flow
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var foregroundColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)
    }
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Recognize",
            description: "Point your camera at any painting and instantly discover its story.",
            systemImage: "camera.viewfinder"
        ),
        OnboardingPage(
            title: "Understand",
            description: "Explore the artist, period, and cultural context behind each masterpiece.",
            systemImage: "book.closed.fill"
        ),
        OnboardingPage(
            title: "Connect",
            description: "Experience art through rich narratives that bring meaning to life.",
            systemImage: "heart.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            page: pages[index],
                            foregroundColor: foregroundColor,
                            secondaryColor: secondaryColor
                        )
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? foregroundColor : foregroundColor.opacity(0.2))
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
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(colorScheme == .dark ? .white : .black)
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
                            .foregroundColor(secondaryColor.opacity(0.8))
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
                    .foregroundColor(foregroundColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free: 3 artworks daily")
                        .font(.system(.subheadline, design: .default))
                        .fontWeight(.medium)
                        .foregroundColor(foregroundColor)
                    
                    Text("Resets every day at midnight")
                        .font(.system(.caption))
                        .foregroundColor(secondaryColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(foregroundColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pro: Unlimited recognition")
                        .font(.system(.subheadline, design: .default))
                        .fontWeight(.medium)
                        .foregroundColor(foregroundColor)
                    
                    Text("€2.99/month or €19.99/year")
                        .font(.system(.caption))
                        .foregroundColor(secondaryColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(foregroundColor.opacity(0.1), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(foregroundColor.opacity(0.02))
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
    let foregroundColor: Color
    let secondaryColor: Color
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundColor(foregroundColor)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.custom("NewYork", size: 48))
                    .fontWeight(.semibold)
                    .foregroundColor(foregroundColor)
                
                Text(page.description)
                    .font(.system(.title3))
                    .foregroundColor(secondaryColor)
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
