//
//  NameAndBirthStepView.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import ComposableArchitecture
import SwiftUI

struct NameAndBirthStepView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TenantOnboardingFeature>
    @Binding var activeField: OnboardingField?
    var keyboardField: FocusState<OnboardingField?>.Binding
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 72) {
            Text("onboarding.tenant.name.title")
                .kohereTextStyle(.heading1Bold)
                .foregroundColor(.neutral90)
                .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("onboarding.profile.lastName")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)
                    
                    OnboardingTextField(
                        text: $store.lastName,
                        activeField: $activeField,
                        keyboardField: keyboardField,
                        equals: .lastName,
                        placeholder: nil
                    )
                }
                .zIndex(1)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("onboarding.profile.firstName")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)
                    
                    OnboardingTextField(
                        text: $store.firstName,
                        activeField: $activeField,
                        keyboardField: keyboardField,
                        equals: .firstName,
                        placeholder: nil
                    )
                    
                    HStack(spacing: 4) {
                        Image(.circleInfo24)
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 12, height: 12)
                        
                        Text("onboarding.name.passportHint")
                            .kohereTextStyle(.caption2Medium)
                    }
                    .foregroundStyle(.primaryNormal)
                    .padding(.top, 8)
                }
                .zIndex(2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("onboarding.profile.birthDate")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)
                    
                    HStack(spacing: 8.5) {
                        KohereDropdownMenu(
                            selectedOption: $store.selectedMonth,
                            activeField: $activeField,
                            equals: .birthMonth,
                            options: DropdownMenuOption.months,
                            listHeight: 176,
                            onExpand: {
                                keyboardField.wrappedValue = nil
                            }
                        )

                        KohereDropdownMenu(
                            selectedOption: $store.selectedDay,
                            activeField: $activeField,
                            equals: .birthDay,
                            options: DropdownMenuOption.days,
                            listHeight: 176,
                            onExpand: {
                                keyboardField.wrappedValue = nil
                            }
                        )

                        KohereDropdownMenu(
                            selectedOption: $store.selectedYear,
                            activeField: $activeField,
                            equals: .birthYear,
                            options: DropdownMenuOption.years,
                            listHeight: 176,
                            onExpand: {
                                keyboardField.wrappedValue = nil
                            }
                        )
                    }
                }
                .zIndex(10)
            }
        }
    }
}
