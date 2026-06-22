//
//  DropdownMenuOption.swift
//  DropdownMenu
//
//  Created by mandoo on 6/21/26.
//

import Foundation

struct DropdownMenuOption: Identifiable, Equatable {
    let option: String
    var id: String { option }
    
    nonisolated static func == (lhs: DropdownMenuOption, rhs: DropdownMenuOption) -> Bool {
        lhs.option == rhs.option
    }
}

extension DropdownMenuOption {
    nonisolated static let months: [DropdownMenuOption] = [
        DropdownMenuOption(option: "JAN"),
        DropdownMenuOption(option: "FEB"),
        DropdownMenuOption(option: "MAR"),
        DropdownMenuOption(option: "APR"),
        DropdownMenuOption(option: "MAY"),
        DropdownMenuOption(option: "JUN"),
        DropdownMenuOption(option: "JUL"),
        DropdownMenuOption(option: "AUG"),
        DropdownMenuOption(option: "SEP"),
        DropdownMenuOption(option: "OCT"),
        DropdownMenuOption(option: "NOV"),
        DropdownMenuOption(option: "DEC")
    ]
    nonisolated static let days = (1...31).map {
        DropdownMenuOption(option: String($0))
    }
    
    nonisolated static let years = (2020...2026).reversed().map {
        DropdownMenuOption(option: String($0))
    }
    
    nonisolated static let visas = ["Diplomatic/Official(A-1,A-2)", "Visa Exempted(B)", "Study(D-2)", "Developer(E-7)"].map {
        DropdownMenuOption(option: $0)
    }
    
    nonisolated static let occupations = ["Undergraduate Student", "Graduate Student", "Developer", "Designer"].map {
        DropdownMenuOption(option: $0)
    }
    
    nonisolated static let nationalities = ["Korea, Republic of", "United States", "Japan", "China"].map {
        DropdownMenuOption(option: $0)
    }
    
    nonisolated static let genders = ["Male", "Female"].map {
        DropdownMenuOption(option: $0)
    }
}
