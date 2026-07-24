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
    @Dependency(\.appleSignInClient)
    var appleSignInClient
    @Dependency(\.socialLoginUseCase)
    var socialLoginUseCase
    @Dependency(\.agreeTermsUseCase)
    var agreeTermsUseCase
    @Dependency(\.keychainClient)
    var keychainClient

    enum LoginSheet: Equatable, Identifiable {
        case notificationOption
        case termsAgreement
        case userTypeSelect
        
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
        var isTermsAgreementRequesting = false
        var selectedTermsDetail: TermsDetailKind?
        
        var isRequiredTermsAgreed: Bool {
            isServiceTermsAgreed && isPrivacyTermsAgreed
        }
        
    }
    
    // MARK: - Action
    
    enum Action: Equatable {
        case googleLoginButtonTapped
        case appleLoginButtonTapped
        case socialLoginCredentialReceived(SocialLoginCredential)
        case loginSuccess(Auth)
        case loginAuthStored(Auth)
        case loginFailure(String)
        
        case notificationSheetDismissed
        case termsAgreementCompleted
        case termsAgreementResponse(Result<TermsAgreement, DataError>)
        case userTypeSelected(OnboardingUserType)
        
        case serviceTermsAgreementToggled
        case privacyTermsAgreementToggled
        case marketingCommunicationsAgreementToggled
        case allTermsAgreementToggled
        
        case termsDetailTapped(TermsDetailKind)
        case termsDetailBackButtonTapped
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
                        let result = try await googleSignInClient.signIn()
                        await send(.socialLoginCredentialReceived(.google(
                            idToken: result.idToken,
                            email: result.email,
                            name: result.name
                        )))
                    } catch {
                        await send(.loginFailure(Self.loginErrorMessage(for: error)))
                    }
                }

            case .appleLoginButtonTapped:
                state.isLoginRequesting = true
                state.loginErrorMessage = nil

                return .run { send in
                    do {
                        let result = try await appleSignInClient.signIn()
                        await send(
                            .socialLoginCredentialReceived(.apple(authorizationCode: result.authorizationCode))
                        )
                    } catch {
                        await send(.loginFailure(error.localizedDescription))
                    }
                }

            case let .socialLoginCredentialReceived(credential):
                return .run { send in
                    do {
                        let auth = try await withThrowingTaskGroup(of: Auth.self) { group in
                            group.addTask {
                                try await socialLoginUseCase.execute(credential)
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
                        await send(.loginFailure(Self.loginErrorMessage(for: error)))
                    }
                }
                
            case let .loginSuccess(auth):
                state.authInfo = auth
                state.loginErrorMessage = nil
                state.currentSheet = auth.onboardingRequired ? .notificationOption : nil
                guard !auth.onboardingRequired else {
                    state.isLoginRequesting = false
                    return .none
                }
                let keychainClient = keychainClient
                return .run { send in
                    try keychainClient.save(auth, for: .auth)
                    await send(.loginAuthStored(auth))
                } catch: { error, send in
                    await send(.loginFailure(Self.loginErrorMessage(for: error)))
                }

            case .loginAuthStored:
                state.isLoginRequesting = false
                return .none
                
            case let .loginFailure(message):
                state.isLoginRequesting = false
                state.loginErrorMessage = message
                return .none
                
            case .notificationSheetDismissed:
                state.currentSheet = .termsAgreement
                return .none
                
            case .termsAgreementCompleted:
                guard state.isRequiredTermsAgreed,
                      !state.isTermsAgreementRequesting,
                      let auth = state.authInfo else { return .none }
                state.isTermsAgreementRequesting = true

                let termsOfServiceAgreed = state.isServiceTermsAgreed
                let privacyPolicyAgreed = state.isPrivacyTermsAgreed
                let marketingAgreed = state.isMarketingCommunicationsAgreed
                let keychainClient = keychainClient

                return .run { send in
                    do {
                        try keychainClient.save(auth, for: .auth)
                        let response = try await agreeTermsUseCase.execute(
                            termsOfServiceAgreed,
                            privacyPolicyAgreed,
                            marketingAgreed
                        )
                        await send(.termsAgreementResponse(.success(response)))
                    } catch {
                        await send(.termsAgreementResponse(.failure(Self.toDataError(error))))
                    }
                }

            case .termsAgreementResponse(.success):
                state.isTermsAgreementRequesting = false
                state.currentSheet = .userTypeSelect
                return .none

            case .termsAgreementResponse(.failure):
                state.isTermsAgreementRequesting = false
                return .none

            case .userTypeSelected:
                state.currentSheet = nil
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
                let targetState = !state.isRequiredTermsAgreed
                state.isServiceTermsAgreed = targetState
                state.isPrivacyTermsAgreed = targetState
                return .none
                
            case let .termsDetailTapped(detail):
                state.selectedTermsDetail = detail
                return .none

            case .termsDetailBackButtonTapped:
                state.selectedTermsDetail = nil
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

private extension LoginFeature {
    static func loginErrorMessage(for error: Error) -> String {
        if let dataError = error as? DataError {
            switch dataError {
            case let .serverError(code, _):
                switch code {
                case "UNAUTHENTICATED", "TOKEN_EXPIRED":
                    return "인증이 필요합니다. 다시 로그인해주세요."
                default:
                    return "로그인에 실패했습니다. 잠시 후 다시 시도해주세요."
                }

            default:
                return "로그인에 실패했습니다. 잠시 후 다시 시도해주세요."
            }
        }

        return error.localizedDescription
    }

    static func toDataError(_ error: Error) -> DataError {
        if let dataError = error as? DataError {
            return dataError
        }

        return .underlying(message: error.localizedDescription)
    }
}
