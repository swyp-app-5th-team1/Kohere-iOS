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
                    
                    KohereDropdownMenu(
                        selectedOption: $store.selectedVisa,
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Occupation")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)
                    
                    KohereDropdownMenu(
                        selectedOption: $store.selectedOccupation,
                        activeField: $activeField,
                        equals: .occupation,
                        options: DropdownMenuOption.occupations,
                        listHeight: 239,
                        onExpand: {
                            keyboardField.wrappedValue = nil
                        }
                    )
                }
                .zIndex(3)
                
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nationality")
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
                        Text("Gender")
                            .kohereTextStyle(.label2Semibold)
                            .foregroundStyle(.neutral90)
                        
                        KohereDropdownMenu(
                            selectedOption: $store.selectedGender,
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
