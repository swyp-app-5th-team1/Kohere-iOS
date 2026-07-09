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
            KohereNavigationBar(left: .backButton({ store.send(.backButtonTapped) }), center: .text("Notifications"), right: .none)
            
            Rectangle()
                .foregroundStyle(.lineNeutral)
                .frame(height: 1)
            
            KohereEmptyView(title: "No notifications yet")
        }
        .background(.backgroundNormalNormal)
    }
}
