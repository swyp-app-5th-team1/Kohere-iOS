//
//  LoginFeature.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

import ComposableArchitecture
import Foundation

@Reducer
struct LoginFeature {
    enum LoginSheet: Equatable, Identifiable {
        case notificationOption
        case termsAgreement
        
        var id: Self { self }
    }
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var isLoginRequesting = false
        var authInfo: Auth?
        var currentSheet: LoginSheet?
        var isServiceTermsAgreed = true
        var isPrivacyTermsAgreed = true
        var isMarketingCommunicationsAgreed = false
        var selectedTermsDetail: TermsDetailKind?
        
        var isRequiredTermsAgreed: Bool {
            isServiceTermsAgreed && isPrivacyTermsAgreed
        }
        
        var isAllTermsAgreed: Bool {
            isServiceTermsAgreed && isPrivacyTermsAgreed && isMarketingCommunicationsAgreed
        }
    }
    
    // MARK: - Action
    
    enum Action: Equatable {
        case googleLoginButtonTapped
        case appleLoginButtonTapped
        case loginSuccess(Auth)
        case loginFailure
        
        case notificationSheetDismissed
        case termsAgreementCompleted
        
        case serviceTermsAgreementToggled
        case privacyTermsAgreementToggled
        case marketingCommunicationsAgreementToggled
        case allTermsAgreementToggled
        
        case termsDetailTapped(TermsDetailKind)
        case termsDetailAgreementTapped(TermsDetailKind)
        
        case setSheet(LoginSheet?)
    }
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .googleLoginButtonTapped, .appleLoginButtonTapped:
                state.isLoginRequesting = true
                
                return .run { send in
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    let mockData = Auth(
                        userId: 1,
                        email: "test@test.com",
                        accessToken: "mock_access_token",
                        refreshToken: "mock_refresh_token"
                    )
                    await send(.loginSuccess(mockData))
                }
                
            case let .loginSuccess(auth):
                state.isLoginRequesting = false
                state.authInfo = auth
                state.currentSheet = .notificationOption
                return .none
                
            case .loginFailure:
                state.isLoginRequesting = false
                return .none
                
            case .notificationSheetDismissed:
                state.currentSheet = .termsAgreement
                return .none
                
            case .termsAgreementCompleted:
                guard state.isRequiredTermsAgreed else { return .none }
                state.currentSheet = nil
                // TODO: 온보딩 또는 홈으로 전환하는 네비게이션 로직 구현
                return .none
                
            case .serviceTermsAgreementToggled:
                state.isServiceTermsAgreed.toggle()
                return .none
                
            case .privacyTermsAgreementToggled:
                state.isPrivacyTermsAgreed.toggle()
                return .none
                
            case .marketingCommunicationsAgreementToggled:
                state.isMarketingCommunicationsAgreed.toggle()
                return .none
                
            case .allTermsAgreementToggled:
                let targetState = !state.isAllTermsAgreed
                state.isServiceTermsAgreed = targetState
                state.isPrivacyTermsAgreed = targetState
                state.isMarketingCommunicationsAgreed = targetState
                return .none
                
            case let .termsDetailTapped(detail):
                state.selectedTermsDetail = detail
                return .none
                
            case let .termsDetailAgreementTapped(detail):
                switch detail {
                case .service:
                    state.isServiceTermsAgreed = true
                case .privacy:
                    state.isPrivacyTermsAgreed = true
                case .marketing:
                    state.isMarketingCommunicationsAgreed = true
                }
                state.selectedTermsDetail = nil
                return .none
                
            case let .setSheet(step):
                state.currentSheet = step
                return .none
            }
        }
    }
}
