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
    @Dependency(\.googleSignInClient)
    var googleSignInClient
    @Dependency(\.socialLoginUseCase)
    var socialLoginUseCase
    @Dependency(\.keychainClient)
    var keychainClient

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
        var loginErrorMessage: String?
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
        case googleIDTokenReceived(String)
        case loginSuccess(Auth)
        case loginFailure(String)
        
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
            case .googleLoginButtonTapped:
                state.isLoginRequesting = true
                state.loginErrorMessage = nil

                return .run { send in
                    do {
                        let idToken = try await googleSignInClient.signIn()
                        await send(.googleIDTokenReceived(idToken))
                    } catch {
                        await send(.loginFailure(error.localizedDescription))
                    }
                }

            case .appleLoginButtonTapped:
                state.loginErrorMessage = "Apple 로그인 연동 전"
                return .none

            case let .googleIDTokenReceived(idToken):
                return .run { send in
                    do {
                        let auth = try await withThrowingTaskGroup(of: Auth.self) { group in
                            group.addTask {
                                try await socialLoginUseCase.execute(.google, idToken)
                            }
                            group.addTask {
                                try await Task.sleep(nanoseconds: 15_000_000_000)
                                throw DataError.underlying(message: "서버 로그인 응답이 지연되고 있습니다.")
                            }

                            guard let auth = try await group.next() else {
                                throw DataError.underlying(message: "서버 로그인 응답을 받지 못했습니다.")
                            }
                            group.cancelAll()
                            return auth
                        }
                        await send(.loginSuccess(auth))
                    } catch {
                        await send(.loginFailure(error.localizedDescription))
                    }
                }
                
            case let .loginSuccess(auth):
                state.isLoginRequesting = false
                state.authInfo = auth
                state.loginErrorMessage = nil
                state.currentSheet = .notificationOption
                return .run { _ in
                    try await keychainClient.saveAuth(auth)
                } catch: { error, send in
                    await send(.loginFailure(error.localizedDescription))
                }
                
            case let .loginFailure(message):
                state.isLoginRequesting = false
                state.loginErrorMessage = message
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
