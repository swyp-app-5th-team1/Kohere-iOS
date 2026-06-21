//
//  DropdownMenuOption.swift
//  DropdownMenu
//
//  Created by mandoo on 6/21/26.
//

import Foundation

struct DropdownMenuOption: Identifiable, Hashable {
	let id = UUID().uuidString
	let option: String
}

extension DropdownMenuOption {
	static let testMonths: [DropdownMenuOption] = [
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
}
