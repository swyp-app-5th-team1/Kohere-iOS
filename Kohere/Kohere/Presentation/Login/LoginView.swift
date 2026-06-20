//
//  LoginView.swift
//  Kohere
//
//  Created by mandoo on 6/17/26.
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
        }
        .animation(.easeInOut(duration: 0.25), value: store.currentSheet)
    }
}

// MARK: - Subviews

extension LoginView {
    
    private var loginContent: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 24) {
                Text("Here you are, in Korea")
                    .kohereTextStyle(.body1Regular)
                    .foregroundColor(.black)
                
                Image(.typoLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 178, height: 48)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Text("In just a minute!")
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
                        
                        Text("Sign in with Google")
                            .kohereTextStyle(.label1Semibold)
                            .foregroundColor(.common100)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white)
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
                        
                        Text("Sign in with Apple")
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
            .frame(height: 418)
            
        case .termsAgreement:
            TermsAgreementBottomSheet(
                onStartTapped: {
                    store.send(.termsAgreementCompleted)
                }
            )
            .frame(height: 374)
        }
    }
}
