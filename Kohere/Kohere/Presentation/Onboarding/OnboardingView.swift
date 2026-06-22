//
//  OnboardingView.swift
//  Kohere
//
//  Created by mandoo on 6/21/26.
//

import SwiftUI

struct OnboardingView: View {
    
    // MARK: - Properties
    
    @State private var selectedMonth: DropdownMenuOption?
    @State private var emailInput: String = ""
    
    // MARK: - Body
    
    var body: some View {
        // TODO: 컴포넌트 테스트 삭제 예정
        VStack(spacing: 16) {
            OnboardingTextField(
                text: $emailInput,
                placeholder: "Enter your email"
            )
            
            DropdownMenu(
                selectedOption: $selectedMonth,
                options: DropdownMenuOption.testMonths
            )
        }
        .padding(.horizontal, 20)
    }
}
