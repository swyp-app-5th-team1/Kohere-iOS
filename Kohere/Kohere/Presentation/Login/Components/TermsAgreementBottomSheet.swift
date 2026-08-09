//
//  TermsAgreementBottomSheet.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

import SwiftUI

struct TermsAgreementBottomSheet: View {
    
    // MARK: - Properties
    
    let isServiceTermsAgreed: Bool
    let isPrivacyTermsAgreed: Bool
    let isMarketingCommunicationsAgreed: Bool
    let isTermsAgreementRequesting: Bool
    
    private var isRequiredTermsAgreed: Bool {
        isServiceTermsAgreed && isPrivacyTermsAgreed
    }
    let onTermsDetailTapped: (TermsDetailKind) -> Void
    let onServiceTermsAgreementTapped: () -> Void
    let onPrivacyTermsAgreementTapped: () -> Void
    let onMarketingCommunicationsAgreementTapped: () -> Void
    let onAllTermsAgreementTapped: () -> Void
    let onStartTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 999)
                .fill(.fillStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            VStack(alignment: .leading) {
                Text(.loginTermsTitle)
                    .kohereTextStyle(.heading2Bold)
                    .foregroundColor(.neutral80)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 30)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(.loginTermsRequiredSectionTitle)
                    .kohereTextStyle(.caption1Regular)
                    .foregroundColor(.neutral60)
                    .padding(.bottom, 12)
                
                Button {
                    onAllTermsAgreementTapped()
                } label: {
                    HStack(spacing: 12) {
                        Image(.checkThick24)
                            .renderingMode(.template)
                            .foregroundColor(isRequiredTermsAgreed ? .statusInfo : .labelAssistive)
                            .frame(width: 24, height: 24)

                        Text(.loginTermsAgreeAllRequired)
                            .kohereTextStyle(.label1Semibold)
                            .foregroundColor(.neutral80)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 24)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(.lineNeutral)
                    .padding(.vertical, 8)
                    .padding(.bottom, 6)
                
                agreementRow(
                    title: .loginTermsServiceRequiredTitle,
                    isAgreed: isServiceTermsAgreed,
                    bottomHitPadding: 22,
                    onAgreementTapped: onServiceTermsAgreementTapped,
                    onDetailTapped: {
                        onTermsDetailTapped(.service)
                    }
                )
                
                agreementRow(
                    title: .loginTermsPrivacyRequiredTitle,
                    isAgreed: isPrivacyTermsAgreed,
                    bottomHitPadding: 22,
                    onAgreementTapped: onPrivacyTermsAgreementTapped,
                    onDetailTapped: {
                        onTermsDetailTapped(.privacy)
                    }
                )
                
                agreementRow(
                    title: .loginTermsMarketingOptionalTitle,
                    isAgreed: isMarketingCommunicationsAgreed,
                    bottomHitPadding: 12,
                    onAgreementTapped: onMarketingCommunicationsAgreementTapped,
                    onDetailTapped: {
                        onTermsDetailTapped(.marketing)
                    }
                )
            }
            .padding(.top, 20)
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 8) {
                Button {
                    if isRequiredTermsAgreed, !isTermsAgreementRequesting {
                        onStartTapped()
                    }
                } label: {
                    Text(.loginTermsStartButton)
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isRequiredTermsAgreed && !isTermsAgreementRequesting ? .primaryNormal : .primary10)
                        .cornerRadius(16)
                }
                .disabled(!isRequiredTermsAgreed || isTermsAgreementRequesting)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .presentationDragIndicator(.hidden)
    }
}

private extension TermsAgreementBottomSheet {
    func agreementRow(
        title: LocalizedStringResource,
        isAgreed: Bool,
        bottomHitPadding: CGFloat,
        onAgreementTapped: @escaping () -> Void,
        onDetailTapped: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Button {
                onAgreementTapped()
            } label: {
                HStack(spacing: 12) {
                    Image(.checkThick16)
                        .renderingMode(.template)
                        .foregroundColor(isAgreed ? .statusInfo : .labelAssistive)
                        .frame(width: 16, height: 16)

                    Text(title)
                        .kohereTextStyle(.label2Medium)
                        .foregroundColor(.neutral80)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 20)
                .padding(.bottom, bottomHitPadding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onDetailTapped()
            } label: {
                Image(.chevronRight16)
                    .renderingMode(.template)
                    .foregroundColor(.neutral20)
                    .frame(width: 44, height: 20)
                    .padding(.bottom, bottomHitPadding)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
