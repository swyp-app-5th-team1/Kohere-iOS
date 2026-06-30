//
//  ListingDetailScrollSupport.swift
//  Kohere
//
//  Created by Codex on 6/29/26.
//

import SwiftUI
import UIKit

enum ListingDetailSection: Int, CaseIterable, Identifiable {
    case roomOffers
    case price
    case property
    case building
    case facility
    case location
    case review

    var id: Self { self }

    var fallbackTitle: String {
        switch self {
        case .roomOffers:
            return "각 방 정보"
        case .price:
            return "가격 정보"
        case .property:
            return "매물 정보"
        case .building:
            return "건물 정보"
        case .facility:
            return "공용 시설"
        case .location:
            return "위치"
        case .review:
            return "리뷰"
        }
    }
}

/// 전체 상세 ScrollView의 세로 offset을 계산하기 위한 iOS 18 미만 fallback key.
struct ListingDetailScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// 섹션별 현재 minY를 모아 sticky 탭의 active 섹션을 판단하기 위한 key.
struct ListingDetailSectionPositionKey: PreferenceKey {
    static var defaultValue: [ListingDetailSection: CGFloat] = [:]

    static func reduce(
        value: inout [ListingDetailSection: CGFloat],
        nextValue: () -> [ListingDetailSection: CGFloat]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

struct ListingDetailScrollViewResolver: UIViewRepresentable {
    let onResolve: (UIScrollView) -> Void

    func makeUIView(context: Context) -> ResolverView {
        ResolverView(onResolve: onResolve)
    }

    func updateUIView(_ uiView: ResolverView, context: Context) {
        uiView.onResolve = onResolve
        uiView.resolveEnclosingScrollView()
    }

    final class ResolverView: UIView {
        var onResolve: (UIScrollView) -> Void

        init(onResolve: @escaping (UIScrollView) -> Void) {
            self.onResolve = onResolve
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            nil
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            resolveEnclosingScrollView()
        }

        func resolveEnclosingScrollView() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                var currentView = superview
                while let view = currentView {
                    if let scrollView = view as? UIScrollView {
                        onResolve(scrollView)
                        return
                    }

                    currentView = view.superview
                }
            }
        }
    }
}
