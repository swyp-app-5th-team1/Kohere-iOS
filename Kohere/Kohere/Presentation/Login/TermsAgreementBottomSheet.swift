//
//  TermsAgreementBottomSheet.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

import SwiftUI

struct TermsAgreementBottomSheet: View {
    
    // MARK: - Properties
    
    @Binding var isServiceTermsAgreed: Bool
    @Binding var isPrivacyTermsAgreed: Bool
    @Binding var isMarketingCommunicationsAgreed: Bool
    
    private var isRequiredTermsAgreed: Bool {
        isServiceTermsAgreed && isPrivacyTermsAgreed
    }
    
    private var isEveryTermAgreed: Bool {
        isRequiredTermsAgreed && isMarketingCommunicationsAgreed
    }
    let onTermsDetailTapped: (TermsDetailKind) -> Void
    let onStartTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 999)
                .fill(.fillStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            VStack(alignment: .leading) {
                Text("We've kept only the essentials\nrequired to use Kohere.")
                    .kohereTextStyle(.heading2Bold)
                    .foregroundColor(.neutral80)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 30)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Required Agreements")
                    .kohereTextStyle(.caption1Regular)
                    .foregroundColor(.neutral60)
                    .padding(.bottom, 12)
                
                HStack(spacing: 12) {
                    Button {
                        toggleAllTerms()
                    } label: {
                        Image(.checkThick24)
                            .renderingMode(.template)
                            .foregroundColor(isEveryTermAgreed ? .statusInfo : .labelAssistive)
                            .frame(width: 24, height: 24)
                    }
                    
                    Text("Agree to All Required Terms")
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(.neutral80)
                }
                .frame(height: 24)
                
                Divider()
                    .background(.lineNeutral)
                    .padding(.vertical, 8)
                    .padding(.bottom, 6)
                
                HStack(spacing: 12) {
                    Button {
                        isServiceTermsAgreed.toggle()
                    } label: {
                        Image(.checkThick16)
                            .renderingMode(.template)
                            .foregroundColor(isServiceTermsAgreed ? .statusInfo : .labelAssistive)
                            .frame(width: 16, height: 16)
                    }
                    
                    Text("Terms of Service *")
                        .kohereTextStyle(.label2Medium)
                        .foregroundColor(.neutral80)
                    
                    Spacer()
                    
                    Button {
                        onTermsDetailTapped(.service)
                    } label: {
                        Image(.chevronRight16)
                            .renderingMode(.template)
                            .foregroundColor(.neutral20)
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(height: 20)
                .padding(.bottom, 22)
                
                HStack(spacing: 12) {
                    Button {
                        isPrivacyTermsAgreed.toggle()
                    } label: {
                        Image(.checkThick16)
                            .renderingMode(.template)
                            .foregroundColor(isPrivacyTermsAgreed ? .statusInfo : .labelAssistive)
                            .frame(width: 16, height: 16)
                    }
                    
                    Text("Privacy Policy *")
                        .kohereTextStyle(.label2Medium)
                        .foregroundColor(.neutral80)
                    
                    Spacer()
                    Button {
                        onTermsDetailTapped(.privacy)
                    } label: {
                        Image(.chevronRight16)
                            .renderingMode(.template)
                            .foregroundColor(.neutral20)
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(height: 20)
                .padding(.bottom, 22)
                
                HStack(spacing: 12) {
                    Button {
                        isMarketingCommunicationsAgreed.toggle()
                    } label: {
                        Image(.checkThick16)
                            .renderingMode(.template)
                            .foregroundColor(isMarketingCommunicationsAgreed ? .statusInfo : .labelAssistive)
                            .frame(width: 16, height: 16)
                    }
                    
                    Text("Marketing Communications")
                        .kohereTextStyle(.label2Medium)
                        .foregroundColor(.neutral80)
                    
                    Spacer()
                    
                    Button {
                        onTermsDetailTapped(.marketing)
                    } label: {
                        Image(.chevronRight16)
                            .renderingMode(.template)
                            .foregroundColor(.neutral20)
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(height: 20)
            }
            .padding(.top, 20)
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 0) {
                Button {
                    if isRequiredTermsAgreed {
                        onStartTapped()
                    }
                } label: {
                    Text("Agree & Get Started")
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isRequiredTermsAgreed ? .primaryNormal : .primary10)
                        .cornerRadius(16)
                }
                .disabled(!isRequiredTermsAgreed)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Method
    
    private func toggleAllTerms() {
        let targetState = !isEveryTermAgreed
        isServiceTermsAgreed = targetState
        isPrivacyTermsAgreed = targetState
        isMarketingCommunicationsAgreed = targetState
    }
}
