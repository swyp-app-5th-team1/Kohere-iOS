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
    
    @Bindable var store: StoreOf<OnboardingFeature>
    @Binding var activeField: OnboardingField?
    var keyboardField: FocusState<OnboardingField?>.Binding
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 72) {
            Text("A few more details\nfor a safer contract")
                .kohereTextStyle(.heading1Bold)
                .foregroundColor(.neutral90)
                .padding(.top, 40)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Visa Status")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)
                    
                    DropdownMenu(
                        selectedOption: $store.selectedVisa,
                        activeField: $activeField,
                        keyboardField: keyboardField,
                        equals: .visaStatus,
                        options: DropdownMenuOption.visas,
                        listHeight: 239
                    )
                }
                .zIndex(4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Occupation")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)
                    
                    DropdownMenu(
                        selectedOption: $store.selectedOccupation,
                        activeField: $activeField,
                        keyboardField: keyboardField,
                        equals: .occupation,
                        options: DropdownMenuOption.occupations,
                        listHeight: 239
                    )
                }
                .zIndex(3)
                
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nationality")
                            .kohereTextStyle(.label2Semibold)
                            .foregroundStyle(.neutral90)
                        
                        DropdownMenu(
                            selectedOption: $store.selectedNationality,
                            activeField: $activeField,
                            keyboardField: keyboardField,
                            equals: .nationality,
                            options: DropdownMenuOption.nationalities,
                            listHeight: 176
                        )
                    }
                    .zIndex(2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gender")
                            .kohereTextStyle(.label2Semibold)
                            .foregroundStyle(.neutral90)
                        
                        DropdownMenu(
                            selectedOption: $store.selectedGender,
                            activeField: $activeField,
                            keyboardField: keyboardField,
                            equals: .gender,
                            options: DropdownMenuOption.genders,
                            listHeight: 92
                        )
                    }
                    .zIndex(1)
                }
            }
        }
    }
}
