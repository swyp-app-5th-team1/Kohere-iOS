//
//  LandlordNameAndBirthStepView.swift
//  Kohere
//
//  Created by mandoo on 7/2/26.
//

import ComposableArchitecture
import SwiftUI

struct LandlordNameAndBirthStepView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<LandlordOnboardingFeature>
    @Binding var activeField: OnboardingField?
    var keyboardField: FocusState<OnboardingField?>.Binding

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 72) {
            Text("반가워요! 가입된 정보가\n맞는지 확인해 드릴게요")
                .kohereTextStyle(.heading1Bold)
                .foregroundColor(.neutral90)
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("이름")
                        .kohereTextStyle(.label2Semibold)
                        .foregroundStyle(.neutral90)

                    OnboardingTextField(
                        text: $store.landlordName,
                        activeField: $activeField,
                        keyboardField: keyboardField,
                        equals: .landlordName,
                        placeholder: nil
                    )
                }
                .zIndex(1)

                VStack(alignment: .leading, spacing: 4) {
                    Text("생년월일")
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
