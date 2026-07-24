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
                    Text("onboarding.profile.fullName")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)

                    Text(store.name)
                        .kohereTextStyle(.label2Medium)
                        .foregroundStyle(.labelAssistive)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                        .background(
                            .backgroundNormalNormal,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.lineAlternative, lineWidth: 1)
                        }
                }
                .zIndex(1)

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
