//
//  AppTab.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import SwiftUI

enum AppTab: Hashable {
    case home
    case community
    case map
    case chat
    case more

    var iconName: String {
        switch self {
        case .home:
            "home_fill_24"
        case .community:
            "persons_fill_24"
        case .map:
            "location_fill_24"
        case .chat:
            "message_fill_24"
        case .more:
            "circle_more_fill_24"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .home:
            "홈"
        case .community:
            "커뮤니티"
        case .map:
            "지도"
        case .chat:
            "채팅"
        case .more:
            "더보기"
        }
    }
}
