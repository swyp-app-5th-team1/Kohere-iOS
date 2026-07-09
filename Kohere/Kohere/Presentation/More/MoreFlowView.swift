//
//  MoreFlowView.swift
//  Kohere
//
//  Created by Codex on 6/18/26.
//

import ComposableArchitecture
import SwiftUI

struct MoreFlowView: View {
    @Bindable var store: StoreOf<MoreFeature>

    var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \MoreFeature.State.path,
                action: \.path
            )
        ) {
            MoreView(store: store)
        } destination: { store in
            switch store.case {
            case let .account(accountStore):
                AccountView(store: accountStore)
                    .navigationBarHidden(true)
            case let .livingGuideDetail(livingGuideDetailStore):
                LivingGuideDetailView(store: livingGuideDetailStore)
                    .navigationBarHidden(true)
            case let .profileEdit(profileEditStore):
                ProfileEditView(store: profileEditStore)
                    .navigationBarHidden(true)
            case let .promoteRoomWeb(promoteRoomWebStore):
                PromoteRoomWebView(store: promoteRoomWebStore)
                    .navigationBarHidden(true)
            case let .setting(settingStore):
                SettingView(store: settingStore)
                    .navigationBarHidden(true)
            case let .settingDocumentWeb(settingDocumentWebStore):
                SettingDocumentWebView(store: settingDocumentWebStore)
                    .navigationBarHidden(true)
            }
        }
    }
}
