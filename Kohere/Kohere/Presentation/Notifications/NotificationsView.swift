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
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(
                left: .backButton({ store.send(.backButtonTapped) }),
                center: .text(String(localized: "notifications.title")),
                right: .none
            )
            
            Rectangle()
                .foregroundStyle(.lineNeutral)
                .frame(height: 1)
            
            KohereEmptyView(title: String(localized: "notifications.empty.title"))
        }
        .background(.backgroundNormalNormal)
    }
}
