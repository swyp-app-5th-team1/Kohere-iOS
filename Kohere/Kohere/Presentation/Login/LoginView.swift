//
//  LoginView.swift
//  Kohere
//
//  Created by soomin on 6/17/26.
//

import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    
    // MARK: - Property
    
    @Bindable var store: StoreOf<LoginFeature>
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            loginContent
            
            if let currentSheet = store.currentSheet {
                Color.materialDimmer
                    .ignoresSafeArea()
                    .onTapGesture {
                        store.send(.setSheet(nil))
                    }
                
                VStack {
                    Spacer()
                    
                    bottomSheetView(currentSheet)
                        .background(.white)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 26,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 26,
                                style: .continuous
                            )
                        )
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
            }
            
            if let selectedTermsDetail = store.selectedTermsDetail {
                termsDetailView(selectedTermsDetail)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.currentSheet)
        .animation(.easeInOut(duration: 0.25), value: store.selectedTermsDetail)
    }
}

// MARK: - Subviews

extension LoginView {
    
    private var loginContent: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 24) {
                Text(.loginTagline)
                    .kohereTextStyle(.body1Regular)
                    .foregroundColor(.black)
                
                Image(.typoLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 178, height: 48)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Text(.loginQuickStartBadge)
                    .kohereTextStyle(.label3Medium)
                    .foregroundColor(.neutral80)
                    .padding(.horizontal, 27)
                    .padding(.vertical, 6)
                    .offset(y: -3)
                    .overlay(
                        Image(.speechBubble)
                            .resizable()
                            .frame(width: 140, height: 33)
                    )
                
                Button {
                    store.send(.googleLoginButtonTapped)
                } label: {
                    HStack(spacing: 12) {
                        Image(.google)
                            .resizable()
                            .frame(width: 24, height: 24)
                        
                        Text(.loginGoogleButton)
                            .kohereTextStyle(.label1Semibold)
                            .foregroundColor(.common100)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.white)
                    .cornerRadius(26)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.lineNormal, lineWidth: 1)
                    )
                }
                .disabled(store.isLoginRequesting)
                
                Button {
                    store.send(.appleLoginButtonTapped)
                } label: {
                    HStack(spacing: 21) {
                        Image(.apple)
                            .resizable()
                            .frame(width: 16, height: 18)
                            .tint(.white)
                        
                        Text(.loginAppleButton)
                            .kohereTextStyle(.label1Semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.black)
                    .cornerRadius(16)
                }
                .disabled(store.isLoginRequesting)

            }
            .padding(.horizontal, 40)
            .padding(.bottom, 150)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.secondaryNormal)
    }
    
    @ViewBuilder
    private func bottomSheetView(_ sheet: LoginFeature.LoginSheet) -> some View {
        switch sheet {
        case .notificationOption:
            NotificationOptionBottomSheet(
                onAllowTapped: {
                    store.send(.notificationSheetDismissed)
                },
                onSkipTapped: {
                    store.send(.notificationSheetDismissed)
                }
            )
            .frame(height: 434)
            
        case .termsAgreement:
            TermsAgreementBottomSheet(
                isServiceTermsAgreed: store.isServiceTermsAgreed,
                isPrivacyTermsAgreed: store.isPrivacyTermsAgreed,
                isMarketingCommunicationsAgreed: store.isMarketingCommunicationsAgreed,
                isTermsAgreementRequesting: store.isTermsAgreementRequesting,
                onTermsDetailTapped: { detail in
                    store.send(.termsDetailTapped(detail))
                },
                onServiceTermsAgreementTapped: {
                    store.send(.serviceTermsAgreementToggled)
                },
                onPrivacyTermsAgreementTapped: {
                    store.send(.privacyTermsAgreementToggled)
                },
                onMarketingCommunicationsAgreementTapped: {
                    store.send(.marketingCommunicationsAgreementToggled)
                },
                onAllTermsAgreementTapped: {
                    store.send(.allTermsAgreementToggled)
                },
                onStartTapped: {
                    store.send(.termsAgreementCompleted)
                }
            )
            .frame(height: 442)

        case .userTypeSelect:
            UserTypeSelectBottomSheet(
                findMyRoomTapped: {
                    store.send(.userTypeSelected(.tenant))
                },
                rentOutTapped: {
                    store.send(.userTypeSelected(.landlord))
                }
            )
            .frame(height: 326)
        }
    }
    
    @ViewBuilder
    private func termsDetailView(_ detail: TermsDetailKind) -> some View {
        switch detail {
        case .service:
            ServiceTermsDetailView(
                onBackTapped: {
                    store.send(.termsDetailBackButtonTapped)
                },
                onAgreeTapped: {
                    store.send(.termsDetailAgreementTapped(.service))
                }
            )
        case .privacy:
            PrivacyTermsDetailView(
                onBackTapped: {
                    store.send(.termsDetailBackButtonTapped)
                },
                onAgreeTapped: {
                    store.send(.termsDetailAgreementTapped(.privacy))
                }
            )
        case .marketing:
            MarketingTermsDetailView(
                onBackTapped: {
                    store.send(.termsDetailBackButtonTapped)
                },
                onAgreeTapped: {
                    store.send(.termsDetailAgreementTapped(.marketing))
                }
            )
        }
    }
}
