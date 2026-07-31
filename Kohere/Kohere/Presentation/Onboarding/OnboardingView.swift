//
//  OnboardingView.swift
//  Kohere
//
//  Created by soomin on 6/21/26.
//

import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {

    // MARK: - Properties

    let store: StoreOf<OnboardingFeature>

    // MARK: - Body

    var body: some View {
        switch store.userType {
        case .tenant:
            if let tenantStore = store.scope(state: \.tenant, action: \.tenant) {
                TenantOnboardingView(store: tenantStore)
            }

        case .landlord:
            if let landlordStore = store.scope(state: \.landlord, action: \.landlord) {
                LandlordOnboardingView(store: landlordStore)
            }
        }
    }
}
