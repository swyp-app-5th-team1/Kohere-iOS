//
//  LivingGuideDetailView.swift
//  Kohere
//
//  Created by mandoo on 7/7/26.
//

import ComposableArchitecture
import SwiftUI
import UIKit

struct LivingGuideDetailView: View {
    
    // MARK: - Property
    
    let store: StoreOf<LivingGuideDetailFeature>

    @State private var showsOpaqueNavigationBar = false
    @State private var fallbackScrollOffsetBaseline: CGFloat?

    private let navigationBarHeight: CGFloat = 100
    private let statusBarHeight: CGFloat = 56
    private let navigationBarTransitionThreshold: CGFloat = 211
    private let titleSpacingBelowBackButton: CGFloat = 23

    private var headerTitleTopPadding: CGFloat {
        navigationBarHeight - statusBarHeight + titleSpacingBelowBackButton
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            guideScrollView

            topNavigationBar
        }
        .background(.staticWhite)
        .background {
            LivingGuideInteractivePopEnabler()
                .frame(width: 0, height: 0)
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var guideScrollView: some View {
        Group {
            if #available(iOS 18.0, *) {
                baseScrollView
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y
                    } action: { _, offset in
                        updateNavigationBarAppearance(offset: offset)
                    }
            } else {
                baseScrollView
                    .onPreferenceChange(LivingGuideScrollOffsetPreferenceKey.self) { minY in
                        if fallbackScrollOffsetBaseline == nil {
                            fallbackScrollOffsetBaseline = minY
                        }

                        let offset = (fallbackScrollOffsetBaseline ?? minY) - minY
                        updateNavigationBarAppearance(offset: offset)
                    }
            }
        }
    }

    private var baseScrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                scrollOffsetReader

                Color.staticWhite
                    .frame(height: statusBarHeight)

                header

                VStack(spacing: 36) {
                    ForEach(store.guide.tips) { tip in
                        LivingGuideTipCard(tip: tip)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .background(.staticWhite)
        .coordinateSpace(name: "LivingGuideScrollCoordinateSpace")
    }
    
    // MARK: - Subview

    private var topNavigationBar: some View {
        HStack {
            Button {
                store.send(.backButtonTapped)
            } label: {
                ZStack {
                    backButtonImage(color: .common0)
                        .opacity(showsOpaqueNavigationBar ? 0 : 1)

                    backButtonImage(color: .labelAlternative)
                        .opacity(showsOpaqueNavigationBar ? 1 : 0)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로가기")

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, statusBarHeight)
        .frame(maxWidth: .infinity)
        .frame(height: navigationBarHeight, alignment: .bottom)
        .background(showsOpaqueNavigationBar ? Color.common0 : Color.clear)
        .zIndex(2)
    }

    private func backButtonImage(color: Color) -> some View {
        Image(.chevronLeft24)
            .renderingMode(.template)
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundStyle(color)
    }

    private var scrollOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: LivingGuideScrollOffsetPreferenceKey.self,
                value: proxy.frame(in: .global).minY
            )
        }
        .frame(height: 0)
    }

    private func updateNavigationBarAppearance(offset: CGFloat) {
        showsOpaqueNavigationBar = max(offset, 0) >= navigationBarTransitionThreshold
    }
    
    private var header: some View {
        ZStack(alignment: .topLeading) {
            Image(store.guide.theme.bannerImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipped()
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.guide.title)
                        .kohereTextStyle(.display2Bold)
                        .foregroundStyle(.staticWhite)
                    
                    Text(store.guide.subtitle)
                        .kohereTextStyle(.body1Regular)
                        .foregroundStyle(.staticWhite)
                }
                .padding(.top, headerTitleTopPadding)
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 210)
    }
}

private struct LivingGuideInteractivePopEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {
        uiViewController.enableInteractivePopGesture()
    }

    final class Controller: UIViewController {
        private weak var popGestureRecognizer: UIGestureRecognizer?
        private weak var originalDelegate: UIGestureRecognizerDelegate?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            enableInteractivePopGesture()
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            restoreInteractivePopGestureDelegate()
        }

        func enableInteractivePopGesture() {
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      let navigationController,
                      navigationController.viewControllers.count > 1,
                      let gestureRecognizer = navigationController.interactivePopGestureRecognizer
                else { return }

                if popGestureRecognizer !== gestureRecognizer {
                    popGestureRecognizer = gestureRecognizer
                    originalDelegate = gestureRecognizer.delegate
                }

                gestureRecognizer.delegate = nil
                gestureRecognizer.isEnabled = true
            }
        }

        private func restoreInteractivePopGestureDelegate() {
            guard let popGestureRecognizer else { return }
            popGestureRecognizer.delegate = originalDelegate
        }
    }
}

private struct LivingGuideScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct LivingGuideTipCard: View {
    
    // MARK: - Property
    
    let tip: LivingGuideTip
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            tipImage
            
            VStack(spacing: 4) {
                Text(tip.title)
                    .kohereTextStyle(.heading3Semibold)
                    .foregroundStyle(.labelNormal)
                    .multilineTextAlignment(.center)
                
                Text(tip.content)
                    .kohereTextStyle(.body2Regular)
                    .foregroundStyle(.labelNeutral)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Subview
    
    private var tipImage: some View {
        KohereRemoteImageView(urlString: tip.imageURL) {
            Color.clear
        }
        .frame(height: 188)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

private extension LivingGuideTheme {
    var bannerImageName: String {
        switch self {
        case .housingScams:
            "korean_tip_1"
            
        case .bankAccount:
            "korean_tip_2"
            
        case .publicTransit:
            "korean_tip_3"
            
        case .healthInsurance:
            "korean_tip_4"
        }
    }
}
