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
    static let months: [DropdownMenuOption] = [
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
    static let days = (1...31).map {
        DropdownMenuOption(option: String($0))
    }
    
    static let years = (1950...2026).reversed().map {
        DropdownMenuOption(option: String($0))
    }
    
    static let visas = ["Diplomatic/Official(A-1,A-2)", "Visa Exempted(B)", "Journalism/Religious Affairs(C-1, D-5, D-6)", "Short Term Visit(C-2, C-3)", "Study(D-2)", "Trainee(D-3, D-4)", "Intra-Company Transfer(D-7)", "Professional(C-4, D-1, D-8, D-9, D-10, E-1, E-2, E-3, E-4, E-5, E-6, E-7)", "Non-Professional(E-8, E-9, E-10)", "Working Holiday(H-1)", "Work and Visit(H-2)", "Family Visitor/Dependent Family(F-1, F-2, F-3)", "Overseas Korean(F-4)", "Permanent Residence(F-5)", "Marrige Migrant(F-6)", "Others(G-1)"].map {
        DropdownMenuOption(option: $0)
    }
    
    static let occupations = ["Undergraduate Student", "Graduate Student", "Exchange Student", "Education/Academic Research", "IT/Software Engineering", "Developer", "Designer"].map {
        DropdownMenuOption(option: $0)
    }
    
    static let nationalities = ["Korea, Republic of", "United States", "Japan", "China", "Vietnam", "Canada", "United Kingdom", "France", "Spain", "Italy", "Turkey", "Hungary"].map {
        DropdownMenuOption(option: $0)
    }
    
    static let genders = ["Male", "Female"].map {
        DropdownMenuOption(option: $0)
    }
}
