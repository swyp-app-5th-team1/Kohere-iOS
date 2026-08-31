//
//  ChatReportView.swift
//  Kohere
//
//  Created by soomin on 8/20/26.
//

import ComposableArchitecture
import SwiftUI

struct ChatReportView: View {
    
    // MARK: - Property
    
    let store: StoreOf<ChatReportFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            KohereNavigationBar(left: .none, center: .text(store.appLanguage.localizedString(forKey: "chat.report.title")),
                                right: .closeButton { store.send(.closeButtonTapped) },
                                rightColor: .labelNormal, backgroundColor: .backgroundNormalAlternative)
            
            VStack(alignment: .leading, spacing: 16) {
                Text(store.appLanguage.localizedString(forKey: "chat.report.privacy-notice"))
                    .kohereTextStyle(.label3Medium)
                    .foregroundStyle(.coolNeutral40)

                VStack(spacing: 8) {
                    ForEach(ChatReportFeature.Reason.allCases) { reason in
                        reasonButton(reason)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            reportButton
        }
        .background(.coolNeutral5)
    }
    
    private func reasonButton(_ reason: ChatReportFeature.Reason) -> some View {
        let isSelected = store.selectedReason == reason
        
        return Button {
            store.send(.reasonTapped(reason))
        } label: {
            HStack {
                Text(store.appLanguage.localizedString(forKey: reason.localizationKey))
                    .kohereTextStyle(.label2Medium)
                    .foregroundStyle(.coolNeutral70)
                
                Spacer(minLength: 0)
                
                Image(.circleCheckFill24)
                    .renderingMode(.template)
                    .foregroundStyle(isSelected ? .primary50 : .coolNeutral10)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.white)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.primary40 : .clear, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
    
    private var reportButton: some View {
        let isEnabled = store.selectedReason != nil && !store.isSubmitting

        return Button {
            store.send(.reportButtonTapped)
        } label: {
            Text(store.appLanguage.localizedString(forKey: "chat.report.action"))
                .kohereTextStyle(.label1Semibold)
        }
        .buttonStyle(ChatReportButtonStyle(isEnabled: isEnabled))
        .disabled(!isEnabled)
        .padding(.horizontal, 20)
    }
}

private struct ChatReportButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(textColor(isPressed: configuration.isPressed))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.lineAlternative, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else { return .fillStrong }
        return isPressed ? .primaryPress : .primaryNormal
    }

    private func textColor(isPressed: Bool) -> Color {
        guard isEnabled else { return .labelNormal }
        return isPressed ? .secondaryNormal : .staticWhite
    }
}
