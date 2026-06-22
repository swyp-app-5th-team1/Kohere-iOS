//
//  NameAndBirthStepView.swift
//  Kohere
//
//  Created by mandoo on 6/23/26.
//

import SwiftUI

struct NameAndBirthStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 72) {
            Text("Welcome!\nLet's check your details.")
                .kohereTextStyle(.heading1Bold)
                .foregroundColor(.neutral90)
                .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Name")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)
                    
                    OnboardingTextField(
                        text: $store.lastName,
                        activeField: $activeField,
                        keyboardField: $keyboardField,
                        equals: .lastName,
                        placeholder: nil
                    )
                }
                .zIndex(1)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("First Name")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)
                    
                    OnboardingTextField(
                        text: $store.firstName,
                        activeField: $activeField,
                        keyboardField: $keyboardField,
                        equals: .firstName,
                        placeholder: nil
                    )
                    
                    HStack(spacing: 4) {
                        Image(.circleInfo24)
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 12, height: 12)
                        
                        Text("Enter your name as shown on your passport")
                            .kohereTextStyle(.caption2Medium)
                    }
                    .foregroundStyle(.primaryNormal)
                    .padding(.top, 8)
                }
                .zIndex(2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date of Birth")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)
                    
                    HStack(spacing: 8.5) {
                        DropdownMenu(
                            selectedOption: $store.selectedMonth,
                            activeField: $activeField,
                            keyboardField: $keyboardField,
                            equals: .birthMonth,
                            options: DropdownMenuOption.months,
                            listHeight: 176
                        )
                        
                        DropdownMenu(
                            selectedOption: $store.selectedDay,
                            activeField: $activeField,
                            keyboardField: $keyboardField,
                            equals: .birthDay,
                            options: DropdownMenuOption.days,
                            listHeight: 176
                        )
                        
                        DropdownMenu(
                            selectedOption: $store.selectedYear,
                            activeField: $activeField,
                            keyboardField: $keyboardField,
                            equals: .birthYear,
                            options: DropdownMenuOption.years,
                            listHeight: 176
                        )
                    }
                }
                .zIndex(10)
            }
        }
    }
}
