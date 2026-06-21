//
//  DropdownMenu.swift
//  DropdownMenu
//
//  Created by mandoo on 6/21/26.
//

import SwiftUI

struct DropdownMenu: View {
    
    // MARK: - Properties
    
    @State private var isOptionsPresented: Bool = false
    @Binding var selectedOption: DropdownMenuOption?
    
    let options: [DropdownMenuOption]
    
    // MARK: - Body
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOptionsPresented.toggle()
            }
        } label: {
            HStack {
                Text(selectedOption?.option ?? "Select")
                    .kohereTextStyle(.label2Medium)
                    .foregroundColor(selectedOption == nil ? .labelAssistive : .labelNeutral)
                
                Spacer()
                
                Image(isOptionsPresented ? .chevronUp16 : .chevronDown16)
                    .renderingMode(.template)
                    .foregroundColor(.coolNeutral20)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isOptionsPresented ? .labelNormal : .lineAlternative, lineWidth: 1)
        }
        .overlay(alignment: .top) {
            if isOptionsPresented {
                DropdownMenuList(options: options) { option in
                    isOptionsPresented = false
                    selectedOption = option
                }
                .offset(y: 46)
                .zIndex(1)
            }
        }
    }
}
