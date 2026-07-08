//
//  KohereNavigationBar.swift
//  Kohere
//
//  Created by mandoo on 6/19/26.
//

import SwiftUI

// MARK: - Navigation Types

enum NavigationLeft {
    case bigLogo
    case smallLogo
    case backButton(() -> Void)
    case closeButton(() -> Void)
}

enum NavigationCenter {
    case none
    case text(String, style: KohereTextStyle = .heading3Semibold)
}

enum NavigationRight {
    case none
    case homeTab(showsHeart: Bool = true, onSearch: () -> Void, onHeart: () -> Void, onNotice: () -> Void)
    case moreTab(showsLanguage: Bool = true, onLanguage: () -> Void, onSetting: () -> Void)
    case detailInfo(onHeart: () -> Void, onShare: () -> Void)
    case searchButton(() -> Void)
    case checkButton(isEnabled: Bool, action: () -> Void)
}

struct KohereNavigationBar: View {
    
    // MARK: - Properties
    
    let left: NavigationLeft
    let center: NavigationCenter
    let right: NavigationRight
    
    let leftColor: Color
    let rightColor: Color
    let backgroundColor: Color
    
    // MARK: - Init
    
    init(
        left: NavigationLeft,
        center: NavigationCenter = .none,
        right: NavigationRight = .none,
        leftColor: Color = .neutral70,
        rightColor: Color = .neutral70,
        backgroundColor: Color = .white
    ) {
        self.left = left
        self.center = center
        self.right = right
        self.leftColor = leftColor
        self.rightColor = rightColor
        self.backgroundColor = backgroundColor
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            centerView
            
            HStack(spacing: 0) {
                leftView
                Spacer()
                rightView
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(backgroundColor)
    }
}

// MARK: - Subviews

extension KohereNavigationBar {
    @ViewBuilder private var leftView: some View {
        switch left {
        case .bigLogo:
            Image(.typoLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 24)
            
        case .smallLogo:
            Image(.smallLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
        case .backButton(let action):
            Button(action: action) {
                Image(.chevronLeft24)
                    .renderingMode(.template)
                    .foregroundColor(leftColor)
                    .frame(width: 24, height: 24)
            }
            
        case .closeButton(let action):
            Button(action: action) {
                Image(.close24)
                    .renderingMode(.template)
                    .foregroundColor(leftColor)
                    .frame(width: 24, height: 24)
            }
        }
    }
    
    @ViewBuilder private var centerView: some View {
        switch center {
        case .none:
            EmptyView()
            
        case let .text(title, style):
            Text(title)
                .kohereTextStyle(style)
                .foregroundColor(.neutral80)
                .lineLimit(1)
        }
    }
    
    @ViewBuilder private var rightView: some View {
        switch right {
        case .none:
            EmptyView()
            
        case .homeTab(let showsHeart, let onSearch, let onHeart, let onNotice):
            HStack(spacing: 18) {
                Button(action: onSearch) {
                    Image(.search24)
                        .renderingMode(.template)
                        .foregroundColor(rightColor)
                        .frame(width: 24, height: 24)
                }
                if showsHeart {
                    Button(action: onHeart) {
                        Image(.heart24)
                            .renderingMode(.template)
                            .foregroundColor(rightColor)
                            .frame(width: 24, height: 24)
                    }
                }
                Button(action: onNotice) {
                    Image(.bell24)
                        .renderingMode(.template)
                        .foregroundColor(rightColor)
                        .frame(width: 24, height: 24)
                }
            }
            
        case .moreTab(let showsLanguage, let onLanguage, let onSetting):
            HStack(spacing: 8) {
                if showsLanguage {
                    Button(action: onLanguage) {
                        Image(.globe24)
                            .renderingMode(.template)
                            .foregroundColor(rightColor)
                            .frame(width: 24, height: 24)
                    }
                }
                Button(action: onSetting) {
                    Image(.setting24)
                        .renderingMode(.template)
                        .foregroundColor(rightColor)
                        .frame(width: 24, height: 24)
                }
            }
            
        case .detailInfo(let onHeart, let onShare):
            HStack(spacing: 6) {
                Button(action: onHeart) {
                    Image(.heart24)
                        .renderingMode(.template)
                        .foregroundColor(rightColor)
                        .frame(width: 24, height: 24)
                }
                Button(action: onShare) {
                    Image(.shareIos24)
                        .renderingMode(.template)
                        .foregroundColor(rightColor)
                        .frame(width: 24, height: 24)
                }
            }
            
        case .searchButton(let onSearch):
            Button(action: onSearch) {
                Image(.search24)
                    .renderingMode(.template)
                    .foregroundColor(rightColor)
                    .frame(width: 24, height: 24)
            }

        case .checkButton(let isEnabled, let action):
            Button(action: action) {
                Image(.circleCheckFill24)
                    .renderingMode(.template)
                    .foregroundColor(isEnabled ? .primary50 : .coolNeutral10)
                    .frame(width: 24, height: 24)
            }
            .disabled(!isEnabled)
            .accessibilityLabel("Save profile")
            .accessibilityHint("Enabled when all required fields are completed.")
        }
    }
}
