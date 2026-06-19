//
//  TermsAgreementBottomSheet.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

import SwiftUI

struct TermsAgreementBottomSheet: View {
    
    // MARK: - Properties
    
    @State private var isServiceTermsAgreed: Bool = false
    @State private var isPrivacyTermsAgreed: Bool = false
    
    private var isAllAgreed: Bool {
        isServiceTermsAgreed && isPrivacyTermsAgreed
    }
    let onStartTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 999)
                .fill(.fillStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            VStack(alignment: .leading) {
                Text("코히어 로그인을 위해\n꼭 필요한 동의만 추렸어요")
                    .kohereTextStyle(.heading2Bold)
                    .foregroundColor(.neutral80)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 30)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("코히어 이용 약관 동의")
                    .kohereTextStyle(.caption1Regular)
                    .foregroundColor(.neutral60)
                    .padding(.bottom, 12)
                
                HStack(spacing: 12) {
                    Button {
                        toggleAllTerms()
                    } label: {
                        Image(.checkThick24)
                            .renderingMode(.template)
                            .foregroundColor(isAllAgreed ? .statusInfo : .labelAssistive)
                            .frame(width: 24, height: 24)
                    }
                    
                    Text("필수 약관 전체 동의")
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(.neutral80)
                }
                .frame(height: 24)
                
                Divider()
                    .background(.lineNeutral)
                    .padding(.vertical, 8)
                    .padding(.bottom, 4)
                
                HStack(spacing: 12) {
                    Button {
                        isServiceTermsAgreed.toggle()
                    } label: {
                        Image(.checkThick16)
                            .renderingMode(.template)
                            .foregroundColor(isServiceTermsAgreed ? .statusInfo : .labelAssistive)
                            .frame(width: 16, height: 16)
                    }
                    
                    Text("서비스 이용약관")
                        .kohereTextStyle(.label2Medium)
                        .foregroundColor(.neutral80)
                    
                    Spacer()
                    
                    Button {
                        // TODO: 약관 상세 뷰로 전체화면 네비게이션 푸시 연결
                    } label: {
                        Image(.chevronRight16)
                            .renderingMode(.template)
                            .foregroundColor(.neutral20)
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(height: 20)
                .padding(.bottom, 20)
                
                HStack(spacing: 12) {
                    Button {
                        isPrivacyTermsAgreed.toggle()
                    } label: {
                        Image(.checkThick16)
                            .renderingMode(.template)
                            .foregroundColor(isPrivacyTermsAgreed ? .statusInfo : .labelAssistive)
                            .frame(width: 16, height: 16)
                    }
                    
                    Text("개인정보처리방침")
                        .kohereTextStyle(.label2Medium)
                        .foregroundColor(.neutral80)
                    
                    Spacer()
                    Button {
                        // TODO: 개인정보 상세 뷰로 전체화면 네비게이션 푸시 연결
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
                    if isAllAgreed {
                        onStartTapped()
                    }
                } label: {
                    Text("시작하기")
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(isAllAgreed ? .primaryNormal : .primary10)
                        .cornerRadius(16)
                }
                .disabled(!isAllAgreed)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Method
    
    private func toggleAllTerms() {
        let targetState = !isAllAgreed
        isServiceTermsAgreed = targetState
        isPrivacyTermsAgreed = targetState
    }
}
