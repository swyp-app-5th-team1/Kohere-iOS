//
//  DetailsStepView.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import ComposableArchitecture
import SwiftUI

struct DetailsStepView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TenantOnboardingFeature>
    @Binding var activeField: OnboardingField?
    var keyboardField: FocusState<OnboardingField?>.Binding
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 72) {
            Text("onboarding.tenant.details.title")
                .kohereTextStyle(.heading1Bold)
                .foregroundColor(.neutral90)
                .padding(.top, 40)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("onboarding.profile.visaStatus")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)
                    
                    KohereDropdownMenu(
                        selectedOption: selectedVisaOption,
                        activeField: $activeField,
                        equals: .visaStatus,
                        options: DropdownMenuOption.visas,
                        listHeight: 239,
                        onExpand: {
                            keyboardField.wrappedValue = nil
                        }
                    )
                }
                .zIndex(4)
                
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("onboarding.profile.nationality")
                            .kohereTextStyle(.label2Semibold)
                            .foregroundStyle(.neutral90)
                        
                        KohereDropdownMenu(
                            selectedOption: $store.selectedNationality,
                            activeField: $activeField,
                            equals: .nationality,
                            options: DropdownMenuOption.nationalities,
                            listHeight: 176,
                            onExpand: {
                                keyboardField.wrappedValue = nil
                            }
                        )
                    }
                    .zIndex(2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("onboarding.profile.gender")
                            .kohereTextStyle(.label2Semibold)
                            .foregroundStyle(.neutral90)
                        
                        KohereDropdownMenu(
                            selectedOption: selectedGenderOption,
                            activeField: $activeField,
                            equals: .gender,
                            options: DropdownMenuOption.genders,
                            listHeight: 92,
                            onExpand: {
                                keyboardField.wrappedValue = nil
                            }
                        )
                    }
                    .zIndex(1)
                }
            }
        }
    }
}

private extension DetailsStepView {
    var selectedVisaOption: Binding<DropdownMenuOption?> {
        Binding(
            get: {
                store.selectedVisa.map(DropdownMenuOption.init)
            },
            set: { option in
                store.selectedVisa = option?.visaType
            }
        )
    }

    var selectedGenderOption: Binding<DropdownMenuOption?> {
        Binding(
            get: {
                store.selectedGender.map(DropdownMenuOption.init)
            },
            set: { option in
                store.selectedGender = option?.gender
            }
        )
    }
}
