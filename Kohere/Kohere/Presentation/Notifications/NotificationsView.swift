//
//  NotificationsView.swift
//  Kohere
//
//  Created by mandoo on 6/24/26.
//

import ComposableArchitecture
import SwiftUI

struct NotificationsView: View {
    
    // MARK: - Property
    
    let store: StoreOf<NotificationsFeature>
    @Environment(\.locale)
    private var locale
    private let mockNotifications = MockNotification.items
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(left: .backButton({ store.send(.backButtonTapped) }),
                                center: .text(AppLanguage(locale: locale).localized(.notificationsTitle)),
                                right: .none)
            
            Rectangle()
                .foregroundStyle(.lineNeutral)
                .frame(height: 1)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(mockNotifications) { notification in
                        NotificationCell(icon: notification.type.icon, category: notification.category,
                                         title: notification.title, time: notification.time, onTap: {})
                    }
                }
                .padding(.top, 20)
            }
        }
        .background(.backgroundNormalNormal)
        .interactivePopGestureEnabled()
    }
}

private struct MockNotification: Identifiable {
    let id: Int
    let type: NotificationType
    let category: String
    let title: String
    let time: String

    static let items = [
        MockNotification(
            id: 0,
            type: .announcement,
            category: "Terms & Privacy",
            title: "The terms have been updated",
            time: "10 min ago"
        ),
        MockNotification(
            id: 1,
            type: .roomFinder,
            category: "Find My Room",
            title: "Find your perfect room in 1 minute",
            time: "1 hr ago"
        ),
        MockNotification(
            id: 2,
            type: .chat,
            category: "Chat",
            title: "New message from \"Goshiwon 1\"",
            time: "2 hr ago"
        ),
        MockNotification(
            id: 3,
            type: .chat,
            category: "Chat",
            title: "New message from \"Goshiwon 2\"",
            time: "2 hr ago"
        ),
        MockNotification(
            id: 4,
            type: .chat,
            category: "Chat",
            title: "New message from \"Goshiwon 3\"",
            time: "2 hr ago"
        )
    ]
}

private enum NotificationType {
    case announcement
    case roomFinder
    case chat

    var icon: ImageResource {
        switch self {
        case .announcement:
            .terms
        case .roomFinder:
            .room
        case .chat:
            .chatNotification
        }
    }
}
